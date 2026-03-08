-- Auto-route app streams to virtual sinks, then sinks to Corsair headset

-- Utility to link ports (from blog)
function link_port(output_port, input_port)
  if not input_port or not output_port then return nil end
  local link_args = {
    ["link.input.node"] = input_port.properties["node.id"],
    ["link.input.port"] = input_port.properties["object.id"],
    ["link.output.node"] = output_port.properties["node.id"],
    ["link.output.port"] = output_port.properties["object.id"],
    ["object.id"] = nil,
    ["object.linger"] = true,
    ["node.description"] = "Auto-route link"
  }
  local link = Link("link-factory", link_args)
  link:activate(1)
  return link
end

-- Main auto-connect function
function auto_connect_ports(args)
  local output_om = ObjectManager {
    Interest {
      type = "port",
      args.output,
      Constraint { "port.direction", "equals", "out" }
    }
  }
  local input_om = ObjectManager {
    Interest {
      type = "port",
      args.input,
      Constraint { "port.direction", "equals", "in" }
    }
  }
  local links = {}

  function _connect()
    for output_ch, input_ch in pairs(args.connect) do
      for output in output_om:iterate { Constraint { "audio.channel", "equals", output_ch } } do
        for input in input_om:iterate { Constraint { "audio.channel", "equals", input_ch } } do
          local link = link_port(output, input)
          if link then table.insert(links, link) end
        end
      end
    end
  end

  output_om:connect("object-added", _connect)
  input_om:connect("object-added", _connect)
  output_om:activate()
  input_om:activate()
end

-- Spotify stream → input.Spotify sink
auto_connect_ports {
  output = Constraint { "application.name", "equals", "spotify" },
  input = Constraint { "node.name", "equals", "input.Spotify" },
  connect = {
    ["FL"] = "FL",
    ["FR"] = "FR"
  }
}

-- Zen → input.Browser
auto_connect_ports {
  output = Constraint { "application.name", "equals", "Zen" },
  input = Constraint { "node.name", "equals", "input.Browser" },
  connect = {
    ["FL"] = "FL",
    ["FR"] = "FR"
  }
}