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

require 'rexml/document'

module ConfigurationHandler

  def update_properties config_file_name, property_kvs
    Chef::Log.debug("Updating configuration file: #{config_file_name}")
    if File.exists?(config_file_name)
      file = File.new(config_file_name)
      doc = Document.new(file)
    else
      new_config = <<EOF
<configuration>
</configuration>
EOF
      doc = REXML::Document.new(new_config)
    end
    
    property_kvs.each_pair { |key,value|  update_property(doc,key,value)}
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    output = formatter.write(doc.root,"")
  end

  def update_property configration, property_name, property_value
    Chef::Log.debug("Configure #{property_name} to value: #{property_value}")
    config_item = REXML::XPath.match(configration, "//name[text() = #{property_name}")
    if config_item.length > 0
      config_item_parent = config_item[config_item.length-1].parent
      config_value = config_item_parent.elements["value"]
      config_value.text = property_value
    else
      Chef::Log.warn("The configuration item does not exist, new item will be added")
      new_prop = Element.new("property")
      new_prop_name = new_prop.add_element("name")
      new_prop_name.text = property_name
      new_prop_value = new_prop.add_element("value")
      new_prop_value.text = property_value
      doc.elments["configuration"] << new_prop
    end
    configration
  end
  
end

class Chef::Recipe
  include ConfigurationHandler
end
