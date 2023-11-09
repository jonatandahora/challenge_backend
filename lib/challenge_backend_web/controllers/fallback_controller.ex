defmodule ChallengeBackendWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use ChallengeBackendWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ChallengeBackendWeb.ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, {step, message}}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ChallengeBackendWeb.ErrorJSON)
    |> render("error.json", %{step: step, message: message})
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: ChallengeBackendWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: ChallengeBackendWeb.ErrorJSON)
    |> render(:"401")
  end
end
