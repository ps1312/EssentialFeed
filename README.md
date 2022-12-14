[![ps1312](https://circleci.com/gh/ps1312/EssentialFeed.svg?style=svg)](<[https://circleci.com/gh/circleci/circleci-docs](https://app.circleci.com/pipelines/github/ps1312/EssentialFeed)>)

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

### - Load Feed From Remote Use Case

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

### - Load Feed From Cache Use Case

#### Primary course (happy path):

1. Execute "Load Image Feed" command
2. System fetches feed data from cache
3. System validades cache is less than 7 days old
4. System creates feed images from cache data
5. System delivers feed images

#### Retrieve cache error (sad path):

1. System delivers error message.

#### Cache is old (sad path):

1. System delivers no feed images

#### Empty cache (sad path):

1. System delivers no feed images

### - Validate Cache Use Case

#### Primary course (happy path):

1. Execute "Validate Cache" command
2. System fetches feed data from cache
3. System validades cache is less than 7 days old

#### Retrieve cache error (sad path):

1. System deletes cache

#### Cache is old (sad path):

1. System deletes cache

### - Cache Feed Use Case

#### Data:

- Feed images

#### Primary course (happy path):

1. Execute "Save Feed Cache" command with above data
2. System deletes old cache
3. System encodes feed images
4. System timestamps newly created cache
5. System persists new cache data
6. System delivers success message

#### Delete cache error (sad path):

1. System delivers error

#### Saving cache error (sad path):

1. System delivers error

### - Load Feed Image Data From Remote Use Case

#### Data:

- URL

#### Primary course (happy path):

1. Execute "Load Remote Feed Image Data" with above data
2. System loads the image from the remote server
3. System delivers the remotely loaded image data

#### Cancel course:

1. System delivers no image data nor error.

#### Connectivity error (sad path):

1. System delivers connectivity error

#### Invalid response (sad path):

1. System delivers invalid data error

### - Load Feed Image Data From Local Use Case

#### Data:

- URL

#### Primary course (happy path):

1. Execute "Load Local Feed Image Data" with above data
2. System fetches local cache for Feed Image
3. System delivers stored data for Feed Image

#### Cancel course:

1. System delivers no image data nor error.

#### Not found (sad path):

1. System delivers notFound error

#### Failure retrieving (sad path):

1. System delivers failed error

### - Cache Feed Image Data

#### Data:

- URL
- Data

#### Primary course (happy path):

1. Execute "Cache Feed Image Data" with above data.
2. System searches for current Feed Image in store
3. System updates the data property with the new image

#### Failure saving new data (sad path):

1. System delivers failed error

---

## Flowchart

![Feed Loading Feature](feed_flowchart.png)

## Model Specs

### Feed Image

| Property      | Type                |
| ------------- | ------------------- |
| `id`          | `UUID`              |
| `description` | `String` (optional) |
| `location`    | `String` (optional) |
| `url`         | `URL`               |

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
## Image Comment Feature Specs

### Story: Customer requests to see image comments

### Narrative

```
As an online customer
I want the app to load image commments
So I can see how people are engaging with images in my feed
```

#### Scenarios (Acceptance criteria)

```
Given the customer has connectivity
 When the customer requests to see comments on an image
 Then the app should display all comments for that image
```

```
Given the customer doesn't have connectivity
 When the customer requests to see comments on an image
 Then the app should display an error message
```

### - Load Image Comments from Remote Use Case

#### Data:

- ImageID

#### Primary course (happy path):

1. Execute "Load Image Comments" with above data.
2. System requests data from remote
3. System validates remote data
4. System converts remote data to Image Comments
5. System delivers Image Comments

#### Connectivity (sad path):

1. System delivers connectivity error

#### Invalid data (sad path):

1. System delivers invalid data error

---

## Model Specs

### Image Comment

| Property          | Type                    |
|-------------------|-------------------------|
| `id`              | `UUID`                  |
| `message`         | `String`                |
| `created_at`      | `Date` (ISO8601 String) |
| `author`          | `CommentAuthorObject`   |

### Image Comment Author

| Property          | Type                |
|-------------------|---------------------|
| `username`        | `String`            |

### Payload contract

```
GET /image/{image-id}/comments

2xx RESPONSE

{
    "items": [
        {
            "id": "a UUID",
            "message": "a message",
            "created_at": "2020-05-20T11:24:59+0000",
            "author": {
                "username": "a username"
            }
        },
        {
            "id": "another UUID",
            "message": "another message",
            "created_at": "2020-05-19T14:23:53+0000",
            "author": {
                "username": "another username"
            }
        },
        ...
    ]
}
```

---

## App Architecture

![](app_architecture.png)
