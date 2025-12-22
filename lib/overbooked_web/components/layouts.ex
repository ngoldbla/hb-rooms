defmodule OverbookedWeb.Layouts do
  @moduledoc """
  Layout components for Phoenix 1.7+.
  
  This module replaces LayoutView for the new component-based layout system.
  Templates are embedded from the templates/layout directory.
  """
  use OverbookedWeb, :html
  use PhoenixHTMLHelpers

  embed_templates "layouts/*"
end
