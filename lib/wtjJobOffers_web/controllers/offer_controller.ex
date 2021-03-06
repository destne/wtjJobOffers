defmodule WtjJobOffersWeb.OfferController do
  use WtjJobOffersWeb, :controller

  alias WtjJobOffers.Jobs
  alias WtjJobOffers.Jobs.Offer

  action_fallback WtjJobOffersWeb.FallbackController

  def index(conn, _params) do
    offers = Jobs.list_offers()
    render(conn, "index.json", offers: offers)
  end

  def create(conn, %{"offer" => offer_params}) do
    with {:ok, %Offer{} = offer} <- Jobs.create_offer(offer_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.offer_path(conn, :show, offer))
      |> render("show.json", offer: offer)
    end
  end

  def show(conn, %{"id" => id}) do
    offer = Jobs.get_offer!(id)
    render(conn, "show.json", offer: offer)
  end

  def show(conn, %{"lat" => lat, "long" => long, "radius" => r}) do
    {lat, _} = Float.parse(lat)
    {long, _} = Float.parse(long)
    {r, _} = Float.parse(r)

    response =
      Jobs.list_offers_inside(lat, long, r)
      |> Enum.map(fn offer ->
        # in meters
        distance = Geocalc.distance_between([lat, long], [offer.latitude, offer.longitude])
        Map.put(offer, :distance, distance / 1000)
      end)

    render(conn, "show.json", offers_found: response)
  end

  def update(conn, %{"id" => id, "offer" => offer_params}) do
    offer = Jobs.get_offer!(id)

    with {:ok, %Offer{} = offer} <- Jobs.update_offer(offer, offer_params) do
      render(conn, "show.json", offer: offer)
    end
  end

  def delete(conn, %{"id" => id}) do
    offer = Jobs.get_offer!(id)

    with {:ok, %Offer{}} <- Jobs.delete_offer(offer) do
      send_resp(conn, :no_content, "")
    end
  end
end
