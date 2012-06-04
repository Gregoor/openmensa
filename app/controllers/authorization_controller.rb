class AuthorizationController < ApplicationController
  before_filter :require_authentication!

  # rescue_from Rack::OAuth2::Server::Authorize::BadRequest do |e|
  #   @error = e
  #   render_error status: e.status
  # end

  def new
    respond *authorizer.call(request.env)
  end

  def create
    respond *authorizer(true).call(request.env)
  end

private
  def respond(status, header, response)
    ["WWW-Authenticate"].each do |key|
      headers[key] = header[key] if header[key].present?
    end
    if response.redirect?
      redirect_to header['Location']
    else
      render :new
    end
  end

  def authorizer(allow_approval = false)
    Rack::OAuth2::Server::Authorize.new do |req, res|
      @client       = Oauth2::Client.find_by_identifier(req.client_id) ||
        req.bad_request!("Invalid client id.")
      @redirect_uri = res.redirect_uri = req.verify_redirect_uri!(@client.redirect_uri)
      if allow_approval || @client.trusted
        if params[:approve] || @client.trusted
          case req.response_type
          when :code
            authorization_code = current_user.authorization_codes.create(:client => @client, :redirect_uri => res.redirect_uri)
            res.code = authorization_code.token
          when :token
            res.access_token = current_user.access_tokens.create(:client => @client).to_bearer_token
          end
          res.approve!
        else
          req.access_denied!
        end
      else
        @response_type = req.response_type
      end
    end
  end
end
