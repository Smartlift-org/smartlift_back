require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "login with correct credentials" do
    # Crear un usuario de prueba
    test_user = users(:test_user)

    # Intentar login
    post "/auth/login", params: {
      email: test_user.email,
      password: "password123"
    }

    # Verificar respuesta
    assert_response :success
    assert_not_nil json_response["token"]
  end

  test "login with incorrect credentials" do
    validation_user = users(:validation_user)
    post "/auth/login", params: {
      email: validation_user.email,
      password: "wrongpassword"
    }

    assert_response :unauthorized
    assert_equal "Credenciales inválidas", json_response["error"]
  end

  test "login with invalid email format" do
    post "/auth/login", params: {
      email: "invalid-email",
      password: "password123"
    }

    assert_response :unprocessable_entity
    assert_equal "Formato de email inválido", json_response["error"]
  end
end
