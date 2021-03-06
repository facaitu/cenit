module RailsAdmin
  module RestApi
    ###
    # Generate PHP code for api service.
    module Php
      ###
      # Returns PHP command for service with given method and path.
      def api_php_code(method, path)
        # Get vars definition.
        data, login = vars(method, path)

        # Generate uri and command.
        command = ""
        command << "$uri = '#{api_uri(method, path)}';\n"
        command << "$headers = array(\n"
        command << "  'Content-Type: application/json',\n"
        command << "  'X-User-Access-Key: #{login ? login.key : '-'}',\n"
        command << "  'X-User-Access-Token: #{login ? login.token : '-'}'\n"
        command << ");\n"
        command << "\n"
        command << "$options = array(\n"
        command << "  'http' => array(\n"
        command << "    'header'  => implode($headers, \"\\r\\n\"),\n"
        command << "    'method'  => '#{method.upcase}',\n"
        command << "    'content' => '#{data.to_json}'\n" unless data.empty?
        command << "  )\n"
        command << ");\n"
        command << "\n"
        command << "$context  = stream_context_create($options);\n"
        command << "$response = file_get_contents($uri, false, $context);\n"
        command << "\n"
        command << "print_r(json_decode($response, true));"

        command
      end
    end
  end
end