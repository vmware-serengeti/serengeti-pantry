#
#   Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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

module HadoopConfigurationFileHandler

  def generate_hadoop_xml_conf(config_file_name, property_kvs)
    if File.exists?(config_file_name)
      file = File.new(config_file_name)
      doc = REXML::Document.new(file)
    else
      new_config = <<EOF
<configuration>
</configuration>
EOF
      doc = REXML::Document.new(new_config)
    end

    property_kvs.each_pair { |key,value|  generate_or_update_property(doc,key,value)}
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    output = formatter.write(doc.root,"")
  end

  def generate_or_update_property(configuration, property_name, property_value)
    found = false
    configuration.elements["configuration"].elements.each do |prop|
      if prop.elements["name"].text == property_name
        config_value = prop.elements["value"]
        config_value.text = property_value
        found = true
      end
    end
    
    if !found
      new_prop = REXML::Element.new("property")
      new_prop_name = new_prop.add_element("name")
      new_prop_name.text = property_name
      new_prop_value = new_prop.add_element("value")
      new_prop_value.text = property_value
      configuration.elements["configuration"] << new_prop
    end
    configuration
  end

end

class Chef::Recipe
  include HadoopConfigurationFileHandler
end
class Chef::Resource::File
  include HadoopConfigurationFileHandler
end
class Chef::Resource::Template
  include HadoopConfigurationFileHandler
end

