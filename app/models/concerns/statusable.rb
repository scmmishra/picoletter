module Statusable
  extend ActiveSupport::Concern

  class_methods do
    def status_checkable(*statuses)
      statuses.each do |status|
        define_method "#{status}?" do
          self.status == status.to_s
        end
      end
    end
  end
end
