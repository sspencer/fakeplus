require 'rubygems'
require 'camping'
require 'json'
require 'yaml'

module Plus
  VERSION = "2.0.4"
  CORELETS = {}
  PKG_DIR = File.expand_path("#{__FILE__}/../../pkg")
  INDEX = YAML.
    load_file(File.expand_path("#{__FILE__}/../services.yaml")).map do |s|
      CORELETS["#{s['name']}/#{s['versionString']}"] = 
        {'strings' => s.delete('strings'), 'package' => "#{s['name']}-#{s['versionString']}",
         'ind' => s['os'].keys.include?("ind")}
      s
    end

  def self.index_for platform
    INDEX.map do |s|
      os, s2, p = s['os'].keys, s.dup, platform
      p = "ind" if os.include? "ind"
      s2['os'] = p
      s2['size'] = s['os'][p]
      s2
    end
  end
end

Camping.goes :Plus

module Plus::Controllers
  class Usage < R '/usage'
    def get
      r 200, "ok", 'Content-Type' => 'text/plain'
    end
  end
  class Permissions < R '/api/v1/permissions'
    def get
      r 200, '', 'X-Sendfile' => File.join(Plus::PKG_DIR, 'Permissions'),
        'Content-Type' => 'application/x-pkcs7-mime; smime-type=signed-data; name="smime.p7m"'
    end
  end
  class Latest < R '/api/v1/platform/latest/version/win32/?'
    def get
      r 200, Plus::VERSION.to_json, 'Content-Type' => 'application/json'
    end
  end
  class CoreletList < R '/api/v1/corelets/(\w+)/?'
    def get platform
      r 200, Plus.index_for(platform).to_json, 'Content-Type' => 'application/json'
    end
  end
  class CoreletString < R '/api/v1/corelet/strings/([\w\.]+/[\w\.]+)/(\w+)/?.*'
    def get name, platform
      c = Plus::CORELETS[name]
      r 200, c['strings'].to_json, 'Content-Type' => 'application/json'
    end
  end
  class CoreletPackage < R '/api/v1/corelet/package/([\w\.]+/[\w\.]+)/(\w+)/?.*'
    def get name, platform
      c = Plus::CORELETS[name]
      path = File.join(Plus::PKG_DIR, c['package'])
      path += "-#{platform}" unless c['ind']
      r 200, '', 'X-Sendfile' => path,
        'Content-Type' => 'application/x-pkcs7-mime; smime-type=signed-data; name="smime.p7m"'
    end
  end
end
