defmodule FoodDiaryWeb.SchemaTest do
  use FoodDiaryWeb.ConnCase, async: true
  use FoodDiaryWeb.SubscriptionCase

  alias FoodDiary.Users

  alias FoodDiary.User

  describe "users query" do
    test "when a valid is given return the user", %{conn: conn} do
      params = %{
        email: "johndoe@bol.com",
        name: "john does"
      }

      {:ok, %User{id: user_id}} = Users.Create.call(params)

      query = """
      {
        user(id: "#{user_id}") {
          name
          email
        }
      }
      """

      expected_response = %{
        "data" => %{"user" => %{"email" => "johndoe@bol.com", "name" => "john does"}}
      }

      response =
        conn
        |> post("api/graphql", %{"query" => query})
        |> json_response(:ok)

      assert response == expected_response
    end

    test "when the user does not exists, returns an error", %{conn: conn} do
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
  end

  describe "users mutations" do
    test "when all params are valid, creates the user", %{conn: conn} do
      mutation = """
        mutation {
          createUser(input: {
            name: "John Doe",
            email: "john@example.com",
          }) {
            id
            name
            email
          }
        }
      """

      response =
        conn
        |> post("api/graphql", %{"query" => mutation})
        |> json_response(:ok)

      assert %{
               "data" => %{
                 "createUser" => %{
                   "email" => "john@example.com",
                   "id" => _id,
                   "name" => "John Doe"
                 }
               }
             } = response
    end
  end

  describe "subscriptions" do
    test "meals subscriptions", %{socket: socket} do
      params = %{
        email: "johndoe@bol.com",
        name: "john does"
      }

      {:ok, %User{id: user_id}} = Users.Create.call(params)

      mutation = """
        mutation {
          createMeal(input: {
            calories: 333.33
            category: DESSERT
            description: "peperoni"
            userId: #{user_id}
          }) {
            calories
            description
            category
          }
        }
      """

      subscription = """
        subscription {
          newMeal {
            description
          }
        }
      """

      # Setup da Subscription

      socket_ref = push_doc(socket, subscription)
      assert_reply socket_ref, :ok, %{subscriptionId: subscription_id}

      # Setup da Mutation
      socket_ref = push_doc(socket, mutation)
      assert_reply socket_ref, :ok, mutation_response

      expected_mutation_response = %{
        data: %{
          "createMeal" => %{
            "calories" => 333.33,
            "category" => "DESSERT",
            "description" => "peperoni"
          }
        }
      }

      expected_subscription_response = %{
        result: %{data: %{"newMeal" => %{"description" => "peperoni"}}},
        subscriptionId: subscription_id
      }

      assert mutation_response == expected_mutation_response

      assert_push "subscription:data", subscription_response
      assert subscription_response == expected_subscription_response
    end
  end
end
