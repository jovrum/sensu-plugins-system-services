#! /usr/bin/env ruby
# encoding: UTF-8

# check-system-services-systemd
#
# DESCRIPTION:
# Check status of system services.
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin, ruby-dbus
#
# USAGE:
#
# NOTES:
#

require 'sensu-plugin/check/cli'
require 'dbus'

class CheckSystemServicesSystemd < Sensu::Plugin::Check::CLI
  option :critical_services,
         short: '-c SERVICES',
         long: '--critical-services SERVICES',
         description: 'issues with any of these comma-separated services are critical events',
         default: ''

  def run
    dbus = DBus::SystemBus.instance
    service = dbus.service('org.freedesktop.systemd1')
    object = service.object('/org/freedesktop/systemd1')
    object.introspect

    critical_services = config[:critical_services]
                        .split(',')
                        .map { |name| name.include?('.') ? name : "#{name}.service" }
                        .to_set

    failing_units = object.ListUnits.first
                          .select { |_name, _desc, _load_state, active_state| active_state == 'failed' }
                          .map { |name, _desc, _load_state, _active_state| name }
                          .to_set

    if failing_units.empty?
      ok
    else
      output = "services are failing: #{failing_units.to_a.sort.join(', ')}"
      if failing_units.intersect?(critical_services)
        critical(output)
      else
        warning(output)
      end
    end
  end
end
