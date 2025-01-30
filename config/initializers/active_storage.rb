require "active_storage"
require "active_storage/service/s3_service"

module ActiveStorage
  class Service::S3Service
    def url(key, **options)
      if public? && AppConfig.get!("R2__PUBLIC_DOMAIN")
        "https://#{AppConfig.get!("R2__PUBLIC_DOMAIN")}/#{key}"
      else
        super
      end
    end
  end
end
