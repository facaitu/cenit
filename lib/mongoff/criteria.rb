module Mongoff
  class Criteria
    include Enumerable
    include Origin::Queryable

    attr_reader :model

    def initialize(model)
      super(Aliases.new(model), Hash.new { |h, k| h[k] = Serializer.new(model, k) })
      @selector = Selector.new(aliases, serializers)
      @model = model
      yield(self) if block_given?
    end

    def count
      query.count
    end

    def size
      count
    end

    def to_ary
      to_a
    end

    def query
      q = model.collection.find(selector)
      options.each do |option, criterion|
        q = q.send(option, criterion)
      end
      q
    end

    def merge(other)
      crit = clone
      crit.merge!(other)
      crit
    end

    def to_criteria
      self
    end

    def merge!(other)
      criteria = other.to_criteria
      selector.merge!(criteria.selector)
      options.merge!(criteria.options)
      self
    end

    def each(*args, &blk)
      query.each do |document|
        m =
          if (type = document['_type'])
            model.class.for(name: type)
          else
            model
          end
        next unless m.submodel_of?(model)
        yield model.record_class.new(m, document, false)
      end
    end

    def method_missing(symbol, *args)
      if (q = query).respond_to?(symbol)
        q.send(symbol, *args)
      else
        super
      end
    end

    def find(*args)
      case (docs = any_in(id: args).to_a).length
      when 0
        nil
      when 1
        docs[0]
      else
        docs
      end
    end

    private

    class Aliases

      attr_reader :model

      def initialize(model)
        @model = model
      end

      def [](field)
        model.attribute_key(field)
      end
    end

    class Serializer

      attr_reader :model
      attr_reader :field

      def initialize(model, field)
        @model = model
        @field =
          if field == 'id'
            :_id
          else
            (model.property_for_attribute(field) || field).to_sym
          end
      end

      def localized?
        false
      end

      def evolve_hash(hash)
        if (association = model.associations[field]) && association.referenced?
          operators = {}
          sub_criteria = {}
          hash.each do |key, value|
            (key.start_with?('$') ? operators : sub_criteria)[key] = value
          end
          if sub_criteria.empty?
            hash
          else
            ids = association.klass.where(sub_criteria).collect(&:id)
            q =
              if association.many?
                unless operators['$elemMatch']
                  operators['$elemMatch'] = {}
                end
              else
                operators
              end
            if (q_ids = q['$in']) && q_ids.is_a?(Array)
              ids += q_ids
            end
            q['$in'] = ids.uniq
            operators
          end
        else
          hash
        end
      end

      def evolve(value)
        if value.respond_to?(:orm_model) && value.respond_to?(:id)
          value.id
        else
          case value
          when Hash, Regexp
            value
          when Enumerable
            value.collect { |v| model.mongo_value(v, field) }
          else
            model.mongo_value(value, field)
          end
        end
      end
    end
  end
end