# Stand-in for the host app's "remote" model reference. node_to_gql only
# reads `proxy_model.typename`, so a struct is enough.
ProxyModelStub = Struct.new(:typename) unless defined?(ProxyModelStub)
