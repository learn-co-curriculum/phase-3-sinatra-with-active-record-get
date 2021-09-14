# Sinatra with Active Record: GET Requests

## Learning Goals

- Handle multiple `GET` requests in a controller
- Use the params hash to look up data with Active Record
- Send a JSON response using data from an Active Record model
- Use the `#to_json` method to serialize JSON data

## Introduction

OK, it's the moment of truth! Our application is all set up; we've reviewed the
file structure and talked about how to run the server. Let's talk about how we
can use Sinatra to access data about our models and send that data as a
response.

Imagine this scenario: you're given the task of creating a new game review
website from scratch. You want a dynamic, highly interactive frontend, so
naturally you choose React. You also need to store the data about your users,
your games, and the reviews somewhere. Well, it sounds like we need a database
for that. Great! We can use Active Record to set up and access data from the
database.

Here's the problem though. React can't communicate directly with the database —
for that, you need Active Record and Ruby. Active Record also doesn't know
anything about your React application (and nor should it!). So then how can
we connect up our React frontend with the database?

Well, it sounds like we need some sort of **interface** between React and our
database. Perhaps some sort of **Application Programming Interface** (or as you
may know it, API). We need a structured way for these two applications to
communicate, using a couple things they **do** have in common: **HTTP** and
**JSON**.

_That_ is what we'll be building for the rest of this section: an API
(specifically, a JSON API) that will allow us to use Active Record to
communicate with a database from a React application — or really, from any
application that speaks HTTP!

## Setup

We'll continue building our Sinatra application using the code from the previous
lesson. Run these commands to install the dependencies and set up the database:

```console
$ bundle install
$ bundle exec rake db:migrate db:seed
```

> **Note**: Running `rake db:migrate db:seed` on one line will run the
> migrations first, then the seed file. It's a nice way to save a few
> keystrokes!

You can view the models in the `app/models` directory, and the migrations in the
`db/migrate` folder. Here's what the relationships will look like in our ERD:

![Game Reviews ERD](https://curriculum-content.s3.amazonaws.com/phase-3/active-record-associations-many-to-many/games-reviews-users-erd.png)

Then, run the server with our new Rake task:

```console
$ bundle exec rake server
```

With that set up, let's work on getting Sinatra and Active Record working
together!

## Accessing the Model From the Controller

Imagine we're building a feature in a React application where we'd like to show
our users a list of all the games in the database. From React, we might have
code similar to the following to make this request for the data:

```jsx
function GameList() {
  const [games, setGames] = useState([]);

  useEffect(() => {
    fetch("http://localhost:9292/games")
      .then((r) => r.json())
      .then((games) => setGames(games));
  }, []);

  return (
    <section>
      {games.map((game) => (
        <GameItem key={game.id} game={game} />
      ))}
    </section>
  );
}
```

It's now our job to set up the server so that when a GET request is made to
`/games`, we return an array of all the games in our database in JSON format.
Let's set up that code in our controller:

```rb
class ApplicationController < Sinatra::Base

  get '/games' do
    # get all the games from the database
    # return a JSON response with an array of all the game data
  end

end
```

How do we get all the games from the database? Thankfully for us, Active Record
makes it simple:

```rb
Game.all
# => [#<Game>, #<Game>, #<Game>]
```

We can also use Active Record's `#to_json` method to convert this list of Active
Record objects to a JSON-formatted string. All together, in our controller,
here's how that would look:

```rb
class ApplicationController < Sinatra::Base

  get '/games' do
    # get all the games from the database
    games = Game.all
    # return a JSON response with an array of all the game data
    games.to_json
  end

end
```

Now head over to the browser, and visit the newly-created `/games` endpoint at
[http://localhost:9292/games](http://localhost:9292/games). You should see a
response with a JSON-formatted array of all the games from the database:

```json
[
  {
    "id": 1,
    "title": "Banjo-Kazooie: Grunty's Revenge",
    "genre": "Real-time strategy",
    "platform": "Nintendo DSi",
    "price": 46,
    "created_at": "2021-07-19T21:55:24.266Z",
    "updated_at": "2021-07-19T21:55:24.266Z"
  },
  {
    "id": 2,
    "title": "The Witcher 2: Assassins of Kings",
    "genre": "Text adventure",
    "platform": "Game Boy Advance",
    "price": 49,
    "created_at": "2021-07-19T21:55:24.298Z",
    "updated_at": "2021-07-19T21:55:24.298Z"
  },
  ...
]
```

Awesome!

You also have a lot of control over how this data is returned by using Active
Record. For example, you could sort the games by title instead of the default
sort order:

```rb
  get '/games' do
    games = Game.all.order(:title)
    games.to_json
  end
```

Or just return the first 10 games:

```rb
  get '/games' do
    games = Game.all.order(:title).limit(10)
    games.to_json
  end
```

Now that you have full control over how the server handles the response, you
have the freedom to design your API as you see fit — just think about what kind
of data you need for your frontend application.

Let's make one more small adjustment to the controller. By default, Sinatra sets
a [response header][] with the `Content-Type: text/html`, since in general, web
servers are used to send HTML content to browsers. Our server, however, will be
used to send JSON data, as you've seen above. We can indicate this by changing the
response header for all our routes by adding this to the controller:

```rb
class ApplicationController < Sinatra::Base

  # Add this line to set the Content-Type header for all responses
  set :default_content_type, 'application/json'

  get '/games' do
    games = Game.all.order(:title).limit(10)
    games.to_json
  end

end
```

[response header]: https://developer.mozilla.org/en-US/docs/Glossary/Response_header

## Getting One Game Using Params

We've got our API set up to handle one feature so far: we can return a list of
all the games in the application. Let's imagine we're building another frontend
feature; this time, we want a component that will just display the details about
one specific game, including its associated reviews. Here's how that component
might look:

```jsx
function GameDetail({ gameId }) {
  const [game, setGame] = useState(null);

  useEffect(() => {
    fetch(`http://localhost:9292/games/${gameId}`)
      .then((r) => r.json())
      .then((game) => setGame(game));
  }, [gameId]);

  if (!game) return <h2>Loading game data...</h2>;

  return (
    <div>
      <h2>{game.title}</h2>
      <p>Genre: {game.genre}</p>
      <h4>Reviews</h4>
      {game.reviews.map((review) => (
        <div>
          <h5>{review.user.name}</h5>
          <p>Score: {review.score}</p>
          <p>Comment: {review.comment}</p>
        </div>
      ))}
    </div>
  );
}
```

So for this feature, we know our server needs to be able to handle a GET request
to return data about a specific game, using the game's ID to find it in the
database. For example, a `GET /games/10` request should return the game with the
ID of 10 from the database; and a `GET /games/29` request should return the game
with the ID of 29.

Let's start by adding a **dynamic route** to the controller to handle any of
these requests:

```rb
class ApplicationController < Sinatra::Base
  set :default_content_type, 'application/json'

  get '/games' do
    games = Game.all.order(:title).limit(10)
    games.to_json
  end

  # use the :id syntax to create a dynamic route
  get '/games/:id' do
    # look up the game in the database using its ID
    # send a JSON-formatted response of the game data
  end

end
```

As we saw earlier, we can access data from the dynamic portion of the URL by
using the **params hash**. For example, if we make a GET request to `/games/10`,
the params hash would look like this:

```rb
{ "id" => "10" }
```

With that in mind, what Active Record method could we use to look up a game with
a specific ID? Either [`.find`][] or [`.find_by`][] would do the trick. Let's
give it a shot:

```rb
  get '/games/:id' do
    # look up the game in the database using its ID
    game = Game.find(params[:id])
    # send a JSON-formatted response of the game data
    game.to_json
  end
```

With this code in place in the controller, try accessing the data about one game
in the browser at
[http://localhost:9292/games/1](http://localhost:9292/games/1). You should see
an object like this in the response:

```json
{
  "id": 1,
  "title": "Banjo-Kazooie: Grunty's Revenge",
  "genre": "Real-time strategy",
  "platform": "Nintendo DSi",
  "price": 46,
  "created_at": "2021-07-19T21:55:24.266Z",
  "updated_at": "2021-07-19T21:55:24.266Z"
}
```

Try making requests using other game IDs as well. As long as the ID exists in
the database, you'll get a response.

### Accessing Associated Data

Right now, our server is returning information about the game, but how can we
also access data about its associated models like the users and reviews? We
could make another endpoint for the user and review data, and make additional
requests from the frontend, but that might get messy. It would be more efficient
to return this data together along with the game data in just one single
response.

Let's take a look at the JSON being returned from the server. How does this Ruby
code:

```rb
game = Game.find(params[:id])
game.to_json
```

...turn into this JSON object?

```json
{
  "id": 1,
  "title": "Banjo-Kazooie: Grunty's Revenge",
  "genre": "Real-time strategy",
  "platform": "Nintendo DSi",
  "price": 46,
  "created_at": "2021-07-19T21:55:24.266Z",
  "updated_at": "2021-07-19T21:55:24.266Z"
}
```

When we're using the `#to_json` method, Active Record [serializes][as_json]
(converts from one format to another) the Active Record object into a JSON
object by getting a list of the model's attributes based on the column names
defined in the database table associated with the model.

Under the hood, the `#to_json` method calls the [`#as_json`][as_json] method to
generate a hash before converting it to a JSON string. Looking at the
documentation for [`#as_json`][as_json], you'll notice we can pass some
additional options to customize how the object is serialized. To include data
about associated models in our JSON, we can pass the `include:` option to
`#to_json`, which will pass it along to `#as_json`:

```rb
  get '/games/:id' do
    game = Game.find(params[:id])

    # include associated reviews in the JSON response
    game.to_json(include: :reviews)
  end
```

This will produce the following JSON structure:

```json
{
  "id": 1,
  "title": "Banjo-Kazooie: Grunty's Revenge",
  "genre": "Real-time strategy",
  "platform": "Nintendo DSi",
  "price": 46,
  "created_at": "2021-07-19T21:55:24.266Z",
  "updated_at": "2021-07-19T21:55:24.266Z",
  "reviews": [
    {
      "id": 1,
      "score": 9,
      "comment": "Qui dolorem dolores occaecati.",
      "game_id": 1,
      "created_at": "2021-07-19T21:55:24.292Z",
      "updated_at": "2021-07-19T21:55:24.292Z",
      "user_id": 2
    },
    {
      "id": 2,
      "score": 3,
      "comment": "Omnis tempora sequi ut.",
      "game_id": 1,
      "created_at": "2021-07-19T21:55:24.295Z",
      "updated_at": "2021-07-19T21:55:24.295Z",
      "user_id": 5
    }
  ]
}
```

Note that this only works because our `Game` model has the correct associations
set up:

```rb
class Game < ActiveRecord::Base
  has_many :reviews
  has_many :users, through: :reviews
end
```

We can even take it a level further, and include the users associated with each
review:

```rb
  get '/games/:id' do
    game = Game.find(params[:id])

    # include associated reviews in the JSON response
    game.to_json(include: { reviews: { include: :user } })
  end
```

```json
{
  "id": 1,
  "title": "Banjo-Kazooie: Grunty's Revenge",
  "genre": "Real-time strategy",
  "platform": "Nintendo DSi",
  "price": 46,
  "created_at": "2021-07-19T21:55:24.266Z",
  "updated_at": "2021-07-19T21:55:24.266Z",
  "reviews": [
    {
      "id": 1,
      "score": 9,
      "comment": "Qui dolorem dolores occaecati.",
      "game_id": 1,
      "created_at": "2021-07-19T21:55:24.292Z",
      "updated_at": "2021-07-19T21:55:24.292Z",
      "user_id": 2,
      "user": {
        "id": 2,
        "name": "Miss Landon Boehm",
        "created_at": "2021-07-19T21:55:24.247Z",
        "updated_at": "2021-07-19T21:55:24.247Z"
      }
    },
    {
      "id": 2,
      "score": 3,
      "comment": "Omnis tempora sequi ut.",
      "game_id": 1,
      "created_at": "2021-07-19T21:55:24.295Z",
      "updated_at": "2021-07-19T21:55:24.295Z",
      "user_id": 5,
      "user": {
        "id": 5,
        "name": "The Hon. Del Ruecker",
        "created_at": "2021-07-19T21:55:24.252Z",
        "updated_at": "2021-07-19T21:55:24.252Z"
      }
    }
  ]
}
```

We can also be more selective about which attributes are returned from each
model with the `only` option:

```rb
  get '/games/:id' do
    game = Game.find(params[:id])

    # include associated reviews in the JSON response
    game.to_json(only: [:id, :title, :genre, :price], include: {
      reviews: { only: [:comment, :score], include: {
        user: { only: [:name] }
      } }
    })
  end
```

```json
{
  "id": 1,
  "title": "Banjo-Kazooie: Grunty's Revenge",
  "genre": "Real-time strategy",
  "price": 46,
  "reviews": [
    {
      "score": 9,
      "comment": "Qui dolorem dolores occaecati.",
      "user": {
        "name": "Miss Landon Boehm"
      }
    },
    {
      "score": 3,
      "comment": "Omnis tempora sequi ut.",
      "user": {
        "name": "The Hon. Del Ruecker"
      }
    }
  ]
}
```

Needless to say, the `#to_json` method has a lot of capabilities! It's very
handy when you need to structure your JSON response in a specific format based
on what data is needed on the frontend.

## Conclusion

In this lesson, you created your very first web API! You learned how to set up
multiple routes to handle different requests based on what kind of data we
needed for a frontend application, and used Active Record to serialize the JSON
response to include all the data needed. At their most basic levels, almost all
web APIs provide a way for clients, like React applications, to interact with a
database and gain access to data in a structured way. Thanks to tools like
Sinatra and Active Record, setting up this interface is fairly straightforward.

## Resources

- [Sinatra Routes](https://rubydoc.info/gems/sinatra#routes)
- [Active Model `#as_json` method][as_json]

[as_json]: https://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html#method-i-as_json
[`.find`]: https://api.rubyonrails.org/v6.1.4/classes/ActiveRecord/FinderMethods.html#method-i-find
[`.find_by`]: https://api.rubyonrails.org/v6.1.4/classes/ActiveRecord/FinderMethods.html#method-i-find_by
