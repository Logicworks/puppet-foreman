Puppet::Type.type(:foreman_smartproxy).provide(:rest_v2) do

  confine :feature => :apipie_bindings

  require 'foreman_api'

  def raise_error(e)
    body = JSON.parse(e.response)["error"]["full_messages"].join(" ") rescue 'N/A'
    fail "Proxy #{resource[:name]} cannot be registered (#{e.message}): #{body}"
  end

  # when both rest and rest_v2 providers are installed, use this one
  def self.specificity
    super + 1
  end

  def api
    @api ||= ForemanApi::Resources::SmartProxy.new({
      :base_url => resource[:base_url],
      :oauth => {
        :consumer_key    => resource[:consumer_key],
        :consumer_secret => resource[:consumer_secret]
      }
    },{
      :headers => {
        :foreman_user => resource[:effective_user],
      },
      :verify_ssl => OpenSSL::SSL::VERIFY_NONE
    })
  end

  # proxy hash or nil
  def proxy
    if @proxy
      @proxy
    else
      @proxy = api.index(:search => "name=#{resource[:name]}")[0]["results"][0]
    end
  rescue Exception => e
    raise_error e
  end

  def id
    proxy ? proxy['id'] : nil
  end

  def exists?
    ! id.nil?
  end

  def create
    api.create({
      :smart_proxy => {
        :name => resource[:name],
        :url  => resource[:url]
      }
    })
  rescue Exception => e
    raise_error e
  end

  def destroy
    api.destroy(:id => id)
    @proxy = nil
  rescue Exception => e
    raise_error e
  end

  def url
    proxy ? proxy['url'] : nil
  end

  def url=(value)
    api.update({ :id => id, :smart_proxy => { :url => value } })
  rescue Exception => e
    raise_error e
  end

  def refresh_features!
    api.refresh(:id => id)
  rescue Exception => e
    raise_error e
  end

end
