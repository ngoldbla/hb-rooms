defmodule Overbooked.EmailRenderer do
  @moduledoc """
  Renders email templates with variable substitution.
  Supports {{variable.path}} syntax for template variables.
  """

  @doc """
  Renders a template string by replacing {{variable}} placeholders with actual values.

  ## Examples

      iex> render("Hello {{user.name}}", %{user: %{name: "John"}})
      "Hello John"

      iex> render("Amount: {{amount}}", %{amount: "$100"})
      "Amount: $100"
  """
  def render(template, assigns) when is_binary(template) and is_map(assigns) do
    Regex.replace(~r/\{\{([^}]+)\}\}/, template, fn _full_match, path ->
      path = String.trim(path)
      get_nested_value(assigns, String.split(path, "."))
    end)
  end

  def render(nil, _assigns), do: ""
  def render(template, _assigns), do: to_string(template)

  @doc """
  Renders a template and returns it as Phoenix.HTML.safe/1.
  """
  def render_html(template, assigns) do
    template
    |> render(assigns)
    |> Phoenix.HTML.raw()
  end

  @doc """
  Generates sample data for preview purposes.
  """
  def sample_assigns(template_type) do
    base_assigns = %{
      user: %{
        name: "Jane Smith",
        email: "jane.smith@example.com"
      },
      url: "https://example.com/action?token=abc123",
      base_url: "https://rooms.example.com"
    }

    case template_type do
      t when t in ["contract_confirmation", "contract_cancelled", "refund_notification"] ->
        Map.merge(base_assigns, %{
          contract: %{
            resource: %{
              name: "Corner Office Suite A",
              description: "Bright corner office with city views"
            },
            start_date: "January 1, 2025",
            end_date: "March 31, 2025",
            duration_months: "3",
            total_amount: "$2,700.00",
            refund_amount: "$900.00",
            refund_id: "re_3QY1234567890"
          }
        })

      "booking_reminder" ->
        Map.merge(base_assigns, %{
          booking: %{
            resource: %{
              name: "Meeting Room A"
            },
            date: "January 15, 2025",
            start_time: "10:00 AM",
            end_time: "11:30 AM"
          }
        })

      "contract_expiration_warning" ->
        Map.merge(base_assigns, %{
          contract: %{
            resource: %{
              name: "Corner Office Suite A"
            },
            end_date: "January 15, 2025",
            days_remaining: "7"
          }
        })

      _ ->
        base_assigns
    end
  end

  @doc """
  Extracts variable names from a template string.
  Returns a list of variable paths found.
  """
  def extract_variables(template) when is_binary(template) do
    ~r/\{\{([^}]+)\}\}/
    |> Regex.scan(template)
    |> Enum.map(fn [_full, path] -> String.trim(path) end)
    |> Enum.uniq()
  end

  def extract_variables(_), do: []

  # Private functions

  defp get_nested_value(map, [key]) when is_map(map) do
    value = Map.get(map, String.to_atom(key)) || Map.get(map, key)
    format_value(value)
  end

  defp get_nested_value(map, [key | rest]) when is_map(map) do
    nested = Map.get(map, String.to_atom(key)) || Map.get(map, key)

    case nested do
      nil -> ""
      value when is_map(value) -> get_nested_value(value, rest)
      _ -> ""
    end
  end

  defp get_nested_value(_, _), do: ""

  defp format_value(nil), do: ""
  defp format_value(value) when is_binary(value), do: value
  defp format_value(value) when is_integer(value), do: Integer.to_string(value)
  defp format_value(value) when is_float(value), do: Float.to_string(value)
  defp format_value(value) when is_atom(value), do: Atom.to_string(value)

  defp format_value(%Date{} = date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp format_value(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %H:%M")
  end

  defp format_value(_), do: ""
end
