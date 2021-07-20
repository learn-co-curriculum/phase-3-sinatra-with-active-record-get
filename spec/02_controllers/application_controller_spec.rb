describe ApplicationController do
  let(:game) { Game.first }

  before do
    game = Game.create(title: "Mario Kart", platform: "Switch", genre: "Racing", price: 60)
    user1 = User.create(name: "Liza")
    user2 = User.create(name: "Duane")
    Review.create(score: 8, comment: "A classic", game_id: game.id, user_id: user1.id)
    Review.create(score: 10, comment: "Wow what a game", game_id: game.id, user_id: user2.id)
  end

  describe 'GET /games' do
    it 'sets the Content-Type header in the response to application/json' do
      get '/games'

      expect(last_response.headers['Content-Type']).to eq('application/json')
    end

    it 'returns an array of JSON objects' do
      get '/games'
      expect(last_response.body).to include_json([
        { title: "Mario Kart", platform: "Switch", genre: "Racing", price: 60 }
      ])
    end
  end

  describe 'GET /games/:id' do
    it 'sets the Content-Type header in the response to application/json' do
      get "/games/#{game.id}"

      expect(last_response.headers['Content-Type']).to eq('application/json')
    end

    it 'returns a single game as JSON with its reviews and users nested' do
      get "/games/#{game.id}"

      expect(last_response.body).to include_json({
        title: "Mario Kart", genre: "Racing", price: 60, reviews: [
          { score: 8, comment: "A classic", user: { name: "Liza" } },
          { score: 10, comment: "Wow what a game", user: { name: "Duane" } }
        ]
      })
    end
  end

end
