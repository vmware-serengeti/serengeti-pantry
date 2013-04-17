#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

require 'xmlsimple'

module ConfigurationHandler

  def update_properties config_file_name, property_kvs
    Chef::Log.debug("Updating configuration file: #{config_file_name}")
    config = XmlSimple.xml_in(config_file_name,"keeproot" => true)
    property_kvs.each_pair { |key,value|  update_property(config,key,value)}
    XmlSimple.xml_out(config,"outputfile" => config_file_name, "rootname" => "")
  end

  def update_property config, property_name, property_value
    Chef::Log.debug("Configure #{property_name} to value: #{property_value}")
    config_item = config['configuration'][0]['property'].select{ |prop| prop['name'][0] == property_name }
    if config_item.length > 0
      config_item[config_item.length-1]['value'] = [property_value]
    else
      Chef::Log.warn("The configuration item does not exist, new item will be added")
      new_config_item = {}
      new_config_item['name'] = [property_name]
      new_config_item['value'] = [property_value]
      config['configuration'][0]['property'] << new_config_item
    end
    config
  end
  
end

class Chef::Recipe
  include ConfigurationHandler
end
