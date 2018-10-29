module Oxidized
  class Nodes < Struct.new(:urls)
    def all
      nodes = []

      # Try to find machines in all puppetdb servers.
      urls.each do |url|
        api = Oxidized::Api.new(url)
        data = api.get('/nodes?format=json').data || []

        data.each do |node|
          nodes << node['full_name']
        end
      end

      nodes
    end

    # returns either the oxidized url or nil
    def find_node(fqdn)
      # Try to find machine in all puppetdb servers.
      urls.each do |url|
        api = Oxidized::Api.new(url)
        data = api.get("/node/show/#{fqdn}?format=json").data
        return url if data && data.class == Hash
      end
      nil
    end
  end
end
