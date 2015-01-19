module Setup
  class TemplatesController < Setup::BaseController
    before_action :find_templates, only: [:show, :update, :destroy]

    def index
      @tenplates = Setup::Template.all
    end

    def show
    end

    def new
      @template = Setup::Template.new
      render json: @template
    end

    def create	  
      @template = Setup::Template.new(permited_attributes)
      if @connection.save
        render json: @template, status: :created, location: @connection
      else
        render json: @template.errors, status: :unprocessable_entity
      end
    end

    def update
      if @template.update_attributes(params[:connection])
        head :no_content
      else
        render json: @template.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @template.destroy
      head :no_content
    end
    
    protected
    def permited_attributes
      params[:template].permit(:name, :library_attributes , :connection_role_attributes, :weebhooks_attributes, :flows_attributes )
    end  
    
    def find_template
      @template = Setup::Template.find_by(slug: params[:id])
    end  
    
  end
end