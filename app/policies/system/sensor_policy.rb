# frozen_string_literal: true

module System
  class SensorPolicy < ::RolePolicy
    section 'System/Sensor'

    class Scope < ::RolePolicy::Scope
    end
  end
end
