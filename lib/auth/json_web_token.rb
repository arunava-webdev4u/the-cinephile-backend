class Auth::JsonWebToken
    # SECRET_KEY = Rails.application.credentials.secret_key_base || "my-super-secret-key"
    SECRET_KEY = "my-super-secret-key"
    EXPIRE_TIME = 1.day.from_now.to_i
    payload = {:username=>"arunava", :password=>"qwerty"}

    def self.encode(payload)
        payload[:exp] = EXPIRE_TIME
        JWT.encode(payload, SECRET_KEY, "HS256")
    end

    def self.decode(token)
        result = JWT.decode(token, SECRET_KEY, true, { :algorithm => 'HS256' } )
        body = HashWithIndifferentAccess.new(result)        # https://api.rubyonrails.org/classes/ActiveSupport/HashWithIndifferentAccess.html
    rescue JWT::ExpiredSignature, JWT::DecodeError
        nil
    end
end
