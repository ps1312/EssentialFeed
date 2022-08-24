# Essential App Case Study

## Image Feed Feature Specs

### Story: Customer requests to see their image feed

### Narrative #1

```
As an online customer
I want the app to automatically load my latest image feed
So I can always enjoy the newest images of my friends
```

#### Scenarios (Acceptance criteria)

```
Given the customer has connectivity
 When the customer requests to see their feed
 Then the app should display the latest feed from remote
  And replace the cache with the new feed
```

### Narrative #2

```
As an offline customer
I want the app to show the latest saved version of my image feed
So I can always enjoy images of my friends
```

#### Scenarios (Acceptance criteria)

```
Given the customer doesn't have connectivity
  And there’s a cached version of the feed
  And the cache is less than seven days old
 When the customer requests to see the feed
 Then the app should display the latest feed saved

Given the customer doesn't have connectivity
  And there’s a cached version of the feed
  And the cache is seven days old or more
 When the customer requests to see the feed
 Then the app should display an error message

Given the customer doesn't have connectivity
  And the cache is empty
 When the customer requests to see the feed
 Then the app should display an error message
```

## Use Cases

### Load Feed From Remote Use Case

#### Data:
- URL

#### Primary course (happy path):
1. Execute "Load Image Feed" command with above data.
2. System downloads data from the URL.
3. System validates downloaded data.
4. System creates image feed from valid data.
5. System delivers image feed.

#### Invalid data – error course (sad path):
1. System delivers invalid data error.

#### No connectivity – error course (sad path):
1. System delivers connectivity error.

### Load Feed From Cache Use Case

#### Primary course (happy path):
1. Execute "Load Image Feed" command
2. System fetches feed data from cache
3. System validades cache is less than 7 days old
4. System creates feed items from cache data
5. System delivers feed items

#### Load cache error (sad path):
1. System delivers error message.

#### Cache is old (sad path):
1. System deletes current cache
2. System delivers no feed items

#### Empty cache (sad path):
1. System delivers no feed items

### Cache Feed Use Case

#### Data:
- Feed items

#### Primary course (happy path):
1. Execute "Save Feed Cache" command with above data
2. System deletes old cache
3. System encodes feed items
4. System timestamps newly created cache
5. System persists new cache data
6. System delivers success message

#### Delete cache error (sad path):
1. System delivers error

#### Saving cache error (sad path):
1. System delivers error

---

## Flowchart

![Feed Loading Feature](feed_flowchart.png)

## Model Specs

### Feed Image

| Property      | Type                |
|---------------|---------------------|
| `id`          | `UUID`              |
| `description` | `String` (optional) |
| `location`    | `String` (optional) |
| `url`            | `URL`               |

### Payload contract

```
GET /feed

200 RESPONSE

{
    "items": [
        {
            "id": "a UUID",
            "description": "a description",
            "location": "a location",
            "image": "https://a-image.url",
        },
        {
            "id": "another UUID",
            "description": "another description",
            "image": "https://another-image.url"
        },
        {
            "id": "even another UUID",
            "location": "even another location",
            "image": "https://even-another-image.url"
        },
        {
            "id": "yet another UUID",
            "image": "https://yet-another-image.url"
        }
        ...
    ]
}
```

---

## App Architecture

![](app_architecture.png)
