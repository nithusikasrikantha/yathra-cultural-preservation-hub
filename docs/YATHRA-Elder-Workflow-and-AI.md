# YATHRA: Elder Component and Application Overview

## 1. Elder component: user flow

**Log in as elder → Home → Explore or Add Story → Review → Publish → Manage collaborations.**

### Sharing an individual story

1. **Home:** Read published stories. For You offers general discovery; Following requests posts from followed communities.
2. **Explore:** Browse categories and communities. Read a community description and confirm Follow. Its member count comes from saved memberships.
3. **Add Story:** Enter the title, typable category, language, and original story. Add optional location, community, time period, banner, and additional photos. Voice tools support composition.
4. **AI Summary:** Generate a short preview, edit and approve it, or skip it. The original remains unchanged.
5. **Review and publish:** Save the story to the backend. Its community and category determine where it can be discovered. Feed cards show the approved summary below the title, or an original-text excerpt.
6. **Story details:** Read the original content and view its photos.

### Collaborating with youth

**Youth request → Elder accepts → Chat → My Projects → Add Content → Draft → Elder review → Approval → Publication.**

- **Notifications / My Connections:** Accept or reject youth requests.
- **Chat:** Exchange memories and cultural knowledge. Optional AI questions help guide the conversation.
- **My Projects:** Add multiple contributions using the same fields as Add Story. Project community context carries into publication.
- **Review:** Youth sends a draft for review. The elder can edit, request changes, or approve. Requested changes return to the youth for revision.
- **Publish:** Only the connected elder can publish an approved collaborative contribution. Both participants are credited.
- **Profile:** Edit name, bio, location, and preferred language. Contributions counts published stories authored by or credited to the user; Connections counts accepted relationships. My Projects and Manage Connections open their respective pages. The back arrow returns to Home.

## 2. Elder component: AI usage

| Where | What AI does | Why it helps |
| --- | --- | --- |
| Add Story / project form | Generates a 1–2 sentence summary from the title, original text, and language | Gives readers a quick preview while preserving the full story |
| Chat: Suggest Questions | Suggests respectful opening questions using the community/topic | Helps start an interview about cultural knowledge |
| Chat: Follow-up Questions | Suggests questions based on recent messages | Helps uncover origins, memories, and missing context |

**How it works:** User requests assistance → Flutter sends an authenticated request → backend checks permissions and input → configured AI model processes the supplied content → backend returns structured output → user reviews or uses it.

The summary is stored separately from the original. Only an approved summary becomes the feed preview. Changing the source invalidates its approval. If generation fails, the elder can retry or skip; chat can use basic template questions as a fallback.

Speech recognition and text-to-speech use device/platform tools. They are separate from the generative AI summary service. Speech recognition currently listens to live microphone speech rather than transcribing an uploaded recording.

AI does not verify cultural truth. Its instructions require source-faithful output, but the elder must check wording and meaning. The API key stays in the backend.

## 3. Elder component: novelty and specialty

The proposed specialty is **elder-controlled cultural preservation supported by youth collaboration and optional AI assistance**.

- **Original voice preserved:** A reviewed summary supports discovery without replacing the elder's narrative.
- **Elder-led approval:** Youth contributions pass through an elder review before collaborative publication.
- **Intergenerational documentation:** Chat and guided questions help youth learn directly from elders.
- **Consistent contributions:** Individual stories and project content use the same authoring fields.
- **Community-linked discovery:** A story's community ID connects it to that community and its followers' feeds.
- **Language support:** Tamil, Sinhala, and English choices support culturally relevant composition.

These are project design contributions. Summarization, chat, and maps are established technologies; claiming worldwide uniqueness would require a separate research and competitor review.

## 4. Full application: purpose and flow

YATHRA brings elders and youth together to document and discover stories, recipes, songs, language, traditions, and local memories.

**Register / log in → Role-based Home → Explore communities, categories, and places → Read or contribute → Connect and collaborate → Review and publish → Manage profile.**

| Application component | Role in the application |
| --- | --- |
| Authentication | Identifies users and controls elder/youth access |
| Elder Home | Reading, discovery, Following, and entry to Add Story |
| Youth Home | Discovery and entry to reading and collaboration |
| Explore | Community and category discovery |
| Community page | Description, confirmed following, actual member count, and community posts |
| Category results | Stories filtered by subject |
| Add Story | Elder authoring with context, media, and optional reviewed summary |
| Story details | Original content and available media |
| Notifications / Connections | Requests, acceptance, and participant relationships |
| Chat | Knowledge exchange with optional question suggestions |
| My Projects | Persistent collaborative drafts and elder review/publication |
| Map | Cultural place discovery and related-story presentation |
| Profile | Personal details, published contribution counts, and accepted connections |

### Application AI capabilities

The connected elder features are summaries and chat questions. Separate youth-oriented services support story translation and cultural-term explanation. The backend also supports chat-to-story generation and category/tag suggestions, but their complete current authoring UI integration is not available.

Chat-to-story requires both participants' consent and would produce a draft for human editing and elder review. It does not automatically publish a conversation.

### Data flow

**App → YATHRA backend → Shared MongoDB database.**

Users, stories, memberships, connections, chat messages, and collaborative workspace content are stored by the backend. One story record can be discovered through multiple views using its category and community association.

For launch, users should connect to one deployed backend and its production database. Sharing a database does not automatically share image files stored on separate developer laptops; production media needs shared storage.

### Current implementation limits

- Home and parts of the youth/map experience still contain sample content. For You is not an AI recommendation engine.
- Map places and related stories use sample data; story location text does not automatically create a real map association.
- Several likes, comments, bookmarks, and insight values are local or demonstrative rather than persisted social features.
- Collaborative drafts persist; individual Save Draft currently does not. Visibility choices lack complete backend privacy enforcement.
- Audio upload/shared playback and recording-only publishing need completion.
- Approved feed summaries work; summary display across every story-detail route is not yet consistent.

These limits should be completed or clearly identified before presenting the entire application as launch-ready.

---

For implementation details and source references, see [the full technical document](YATHRA-Elder-Workflow-and-AI-Full.md).
