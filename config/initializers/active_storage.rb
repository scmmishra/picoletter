require "active_storage"
require "active_storage/service/s3_service"

module ActiveStorage
  class Service::S3Service
    def url(key, **options)
      if public? && (domain = AppConfig.get("R2__PUBLIC_DOMAIN"))
        "https://#{domain}/#{key}"
      else
        super
      end
    end
  end
end
