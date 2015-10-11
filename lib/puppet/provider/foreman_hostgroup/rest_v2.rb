require 'foreman_api'

Puppet::Type.type(:foreman_hostgroup).provide(:rest_v2) do

  def raise_error(e)
    body = JSON.parse(e.response)["error"]["full_messages"].join(" ") rescue 'N/A'
    fail "Hostgroup #{resource[:name]} cannot be registered (#{e.message}): #{body}"
  end

  # when both rest and rest_v2 providers are installed, use this one
  def self.specificity
    super + 1
  end

  def hostgroups
    @hostgroups ||= ForemanApi::Resources::Hostgroup.new({
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

  def smartproxy=(value)
    hostgroups.update({ "id" => id, "hostgroup" => { "puppet_proxy_id" => smartproxy_object["id"]}})
  rescue Exception => e
    raise_error e
  end

  def smartproxies
    @smartproxies ||= ForemanApi::Resources::SmartProxy.new({
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

  def smartproxy_object
    smartproxies.index(search: "name=#{resource[:smartproxy]}")[0]['results'][0]
  end

  def smartproxy_id
    @hostgroup ? hostgroup["puppet_proxy_id"] : nil    
  end

  def smartproxy
    smartproxies.show("id" => hostgroup['puppet_proxy_id'])[0]["name"]
  end

#
#  Environment section
#
  def environment_object
    @environment_object ||= ForemanApi::Resources::Environment.new({
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
    }).index(search: "name=#{resource[:environment]}")[0]['results'][0]
  end

  def environment_id
    @hostgroup ? hostgroup["environment_id"] : nil
  end

  def environment
    @hostgroup ? hostgroup["environment_name"] : nil
  end

  def environment=(value)
    hostgroups.update({ "id" => id, "hostgroup" => { "environment_id" => environment_object["id"]}})
  rescue Exception => e
    raise_error e
  end

  def hostgroupclass_api
    @hostgroupclass_api ||= ForemanApi::Resources::HostgroupClass.new({
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

  def hostgroupclasses
    @hostgroupclasses = hostgroupclass_api.index("hostgroup_id" => id)[0]["results"].inject({}){|h,c|
      obj = puppetclass_object(c)
      obj ? h.merge(obj["name"] => obj["id"]) : h
    }
  end

  def puppetclass_api
    if @puppetclass_api
      @puppetclass_api
    else
      @puppetclass_api ||= ForemanApi::Resources::Puppetclass.new({
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
  end

  def puppetclass_object(id)
    puppetclass_api.show("id" => id)[0]
  end

  def puppetclass
    hostgroupclasses.keys
  end

  def puppetclass=(classes)
    class_ids = classes.inject([]){|a,c|
      if puppetclass_object(c)
        a.push puppetclass_object(c)["id"]
      else
        a
      end
    }

    add    = class_ids - hostgroupclasses.values
    remove = hostgroupclasses.values - class_ids

    remove.each{|cid|
      hostgroupclass_api.destroy({"id" => cid, "hostgroup_id" => id})
    }

    add.each{|cid|
      hostgroupclass_api.create("puppetclass_id" => cid, "hostgroup_id" => id)
    }

  rescue Exception => e
    raise_error e
  end

  # hostgroup hash or nil
  def hostgroup
    @hostgroup = hostgroups.index(:search => "name=#{resource[:name]}")[0]['results'][0]    # end
  rescue Exception => e
    raise_error e
  end

  def id
    hostgroup ? hostgroup['id'] : nil
  end

  def exists?
    ! id.nil?
  end

  def create
    hostgroups.create({
      :hostgroup => {
        :name => resource[:name]
      }
    })
  rescue Exception => e
    raise_error e
  end

  def destroy
    hostgroup.destroy(:id => id)
    @hostgroup = nil
  rescue Exception => e
    raise_error e
  end

  def refresh_features!
    hostgroup.refresh(:id => id)
  rescue Exception => e
    raise_error e
  end
end
