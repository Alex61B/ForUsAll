module JsonApiHelpers
  def json_response
    JSON.parse(response.body)
  end

  def jsonapi_headers
    { "Content-Type" => "application/vnd.api+json", "Accept" => "application/vnd.api+json" }
  end
end

RSpec.configure do |config|
  config.include JsonApiHelpers, type: :request
end
