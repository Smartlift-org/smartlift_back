class ApiStatusController < ApplicationController
  skip_before_action :authorize_request, only: [ :index ]

  def index
    render json: {
      status: "online",
      version: "1.0.0",
      endpoints: {
        users: {
          create: "/users",
          update: "/users/:id",
          profile: "/profile"
        },
        auth: {
          login: "/auth/login"
        },
        exercises: {
          index: "/exercises",
          show: "/exercises/:id",
          create: "/exercises",
          update: "/exercises/:id",
          destroy: "/exercises/:id"
        },
        user_stats: {
          index: "/user_stats",
          create: "/user_stats",
          update: "/user_stats"
        }
      }
    }
  end
end
