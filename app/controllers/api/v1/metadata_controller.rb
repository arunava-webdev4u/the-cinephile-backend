class Api::V1::MetadataController < Api::V1::ApplicationController
  skip_before_action :authenticate_user!, only: [ :countries ]

  def countries
    render json: ISO3166::Country.all.map { |c| { code: c.number, name: c.common_name } }
  end
end
