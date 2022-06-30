defmodule FoodDiaryWeb.SchemaTest do
  use FoodDiaryWeb.ConnCase, async: true

  alias FoodDiary.Users

  alias FoodDiary.User

  describe "users query" do
    test "when a valid is given return the user", %{conn: conn} do
      expected_response = %{
        "data" => %{"user" => nil},
        "errors" => [
          %{
            "locations" => [%{"column" => 3, "line" => 2}],
            "message" => "User not found",
            "path" => ["user"]
          }
        ]
      }

      query = """
      {
        user(id: "#{123}") {
          name
          email
        }
      }
      """

      response =
        conn
        |> post("api/graphql", %{"query" => query})
        |> json_response(:ok)

      assert response == expected_response
    end

    test "when the user does not exists, returns an error", %{conn: conn} do
      params = %{
        email: "johndoe@bol.com",
        name: "john does"
      }

      {:ok, %User{id: user_id}} = Users.Create.call(params)

      expected_response = %{
        "data" => %{"user" => %{"email" => "johndoe@bol.com", "name" => "john does"}}
      }

      query = """
      {
        user(id: "#{user_id}") {
          name
          email
        }
      }
      """

      response =
        conn
        |> post("api/graphql", %{"query" => query})
        |> json_response(:ok)

      assert response == expected_response
    end
  end
end
