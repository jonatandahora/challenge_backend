defmodule ChallengeBackendWeb.ErrorJSON do
  @moduledoc """
  Renders common errors
  """

  @doc """
  Renders a normalized error message from a Ecto.Multi
  """
  def render("error.json", %{step: step, message: message}) do
    %{errors: %{detail: %{step => message}}}
  end

  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
