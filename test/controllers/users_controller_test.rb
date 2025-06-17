require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @test_user = users(:test_user)
    # Obtener token de autenticación
    post "/auth/login", params: {
      email: @test_user.email,
      password: "password123"
    }
    @auth_token = json_response["token"]
  end

  test "create user with valid data" do
    assert_difference("User.count") do
      post "/users", params: {
        first_name: "Test",
        last_name: "User",
        email: "new@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_response :created
    assert_equal "Test", json_response["first_name"]
    assert_equal "User", json_response["last_name"]
    assert_equal "new@example.com", json_response["email"]
  end

  test "create user with invalid email" do
    post "/users", params: {
      first_name: "Test",
      last_name: "User",
      email: "invalid-email",
      password: "password123",
      password_confirmation: "password123"
    }

    assert_response :unprocessable_entity
    assert_equal "Formato de email inválido", json_response["error"]
  end

  test "create user with duplicate email" do
    # Intentar crear usuario con el mismo email
    post "/users", params: {
      first_name: "Test",
      last_name: "User",
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    }

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Email ya está en uso"
  end

  test "update user with valid data" do
    patch "/users/#{@test_user.id}",
      params: {
        first_name: "Updated",
        last_name: "User",
        email: "updated@example.com"
      },
      headers: { "Authorization" => "Bearer #{@auth_token}" }

    assert_response :ok
    assert_equal "Updated", json_response["first_name"]
    assert_equal "User", json_response["last_name"]
    assert_equal "updated@example.com", json_response["email"]
  end

  test "update user with invalid email" do
    patch "/users/#{@test_user.id}",
      params: {
        email: "invalid-email"
      },
      headers: { "Authorization" => "Bearer #{@auth_token}" }

    assert_response :unprocessable_entity
    assert_includes json_response["errors"], "Email debe tener un formato válido"
  end

  test "update non-existent user" do
    patch "/users/999",
      params: {
        first_name: "Updated",
        last_name: "User"
      },
      headers: { "Authorization" => "Bearer #{@auth_token}" }

    assert_response :not_found
    assert_equal "Usuario no encontrado", json_response["error"]
  end
end
