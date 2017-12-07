require 'ostruct'
require 'yaml'

require 'phobos'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'sinatra/base'

require 'phobos_prometheus/version'
require 'phobos_prometheus/collector'
require 'phobos_prometheus/exporter_helper'
require 'phobos_prometheus/exporter'

# Prometheus collector for Phobos
module PhobosPrometheus
  class << self
    attr_reader :config

    def subscribe
      config.metrics.each do |metric|
        Phobos.logger.info { Hash(message: 'PhobosPrometheus register subscriber', metric: metric) }
        Collector.create(
          instrumentation_label: metric.instrumentation_label,
          buckets: bucket_config(metric.bucket)
        )
      end

      Phobos.logger.info { Hash(message: 'PhobosPrometheus subscribed', env: ENV['RACK_ENV']) }

      self
    end

    def configure(configuration)
      @config = Phobos::DeepStruct.new(fetch_settings(configuration))

      Phobos.logger.info { Hash(message: 'PhobosPrometheus configured', env: ENV['RACK_ENV']) }
    end

    private

    def fetch_settings(configuration)
      return configuration.to_h if configuration.respond_to?(:to_h)

      YAML.safe_load(ERB.new(File.read(File.expand_path(configuration))).result)
    end

    def bucket_config(name)
      config.buckets.find { |b| b.name == name }.buckets
    end
  end
end
