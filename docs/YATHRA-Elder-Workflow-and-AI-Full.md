# YATHRA: Elder User Workflow, Components, and AI

Prepared from the current Flutter frontend and Express/Mongoose backend on 14 October 2026.

This document explains the elder experience, its relationship to youth participation, the purpose and operation of AI, and the application's proposed novelty. Implementation status is stated explicitly: a visible button, backend endpoint, and complete working feature are different things. This is a description of the current application and its intended value, not a claim that all launch work is complete.

## 1. Product purpose and participants

YATHRA helps preserve cultural knowledge through stories, recipes, songs, proverbs, practices, and personal memories. An elder supplies lived experience and cultural context. A youth discovers that knowledge and can help document it through an accepted collaboration. Communities organize participation; categories organize subject matter; the map provides geographic discovery.

The elder is the knowledge contributor and reviewer. AI assists expression and discovery. The elder remains responsible for checking whether a generated summary or collaborative draft represents the story correctly.

The application supports Tamil, Sinhala, and English in its story creation language selector. These choices describe the story language; they do not mean that every screen and fallback message is already translated.

## 2. Overall elder journey

1. Register or log in with the elder role.
2. Enter the Elder Home experience within the shared application shell.
3. Read stories through For You, or use Following to request stories from followed communities.
4. Explore communities and categories; follow relevant communities after reviewing their descriptions.
5. Create an individual story from Home or a followed community.
6. Add the original content, category, language, optional context, and photos.
7. Generate, edit, approve, or skip the optional AI summary.
8. Review and publish the story.
9. Receive requests from youth, accept a suitable request, and discuss cultural knowledge in chat.
10. Open My Projects, work on contributions, review youth submissions, and publish approved collaborative content.
11. Maintain the profile and check actual published contribution and accepted connection counts.

There are two publishing paths: individual elder publishing and collaborative publishing. The individual route does not enter the collaboration review status machine. The collaborative route requires the connected elder's approval before publication.

## 3. Navigation and component map

| Component | Elder's purpose | Connected destination or data |
| --- | --- | --- |
| Home | Read stories and start a contribution | Stories API and Add Story |
| Notifications | Review pending youth requests | Connection notifications and response endpoints |
| Connections menu | Access projects and relationships | My Projects or My Connections |
| Profile icon | Manage identity and contribution overview | Elder Profile |
| Explore | Discover communities and categories | Community catalogue, memberships, and story filters |
| Community details | Understand, follow, and contribute to a community | Community membership and community-filtered stories |
| Category results | Find stories by subject | Category-filtered Stories API |
| Add Story | Compose an individual cultural story | Image upload, optional AI summary, story creation |
| Story details | Read the original and view its media | Selected story content and photo gallery |
| My Connections | Manage youth relationships | Pending, accepted, and other connection states |
| Chat | Exchange knowledge and ask follow-up questions | Persisted connection messages and question suggestions |
| My Projects | Organize collaborative contributions | Accepted connections and workspace items |
| Workspace editor | Draft, review, approve, and publish | Shared Add Story fields plus project controls |
| Map | Discover cultural places | Current sample place catalogue and related sample stories |
| Profile | Edit personal details and view participation | Profile API, authenticated counts, projects, connections |

## 4. Registration, login, and identity

The backend stores users with their name, email, password hash, role, and profile information. Login returns a token. The frontend stores that token using secure storage and sends it in the Authorization header for protected requests.

The shell selects elder or youth screens according to the role. Elder profile editing saves name, bio, location, and preferred language through the authenticated elder profile endpoint. Existing avatar and other profile information are preserved by that update.

When a developer changes to a shared database, previously created accounts in a different database are not automatically available. The user must sign in with an account in the selected shared database, or the team must migrate the relevant records.

## 5. Elder Home

### Header and navigation

The header shows YATHRA and the discovery heading. On the right, the order is notifications, the connections menu, and profile. The connections menu opens My Projects or My Connections. The profile button selects the Profile tab. Existing brown and cream styling remains the visual identity.

### Feed behavior

For You requests published stories from the backend. It is currently a general discovery feed; its name should not be presented as proof of an AI recommendation engine. Following requests stories whose community IDs match the current user's saved memberships. Unfollowed communities are excluded by the backend filter.

Home fetches an initial set of up to 20 stories. Search currently filters the loaded home stories by title, content, and location; it is not a complete search of every record in the database. Pull to refresh and the published-content signal reload story data.

The elder Home also still contains demonstration cards. These must be distinguished from real database stories during demonstrations and removed or deliberately separated before launch. The backend Following filter is real, but sample UI content should not be described as evidence of that filtering.

### Story card layout

The real story card presents the author and community/time information, banner image, category pill, title, preview, language, location/read-time metadata, and interaction controls.

The preview uses an approved, nonempty AI summary. Otherwise, it uses the original story text as an excerpt. The card truncates the preview for the available space. Opening the card leads to the original story.

Read time is estimated from the original word count, using approximately 180 words per minute. It is an estimate, not a measurement of an individual reader.

The shared real card's like state is local UI state. Sharing copies the story text to the clipboard. A bookmark requires the caller's save behavior; the card alone does not establish a server-backed saved-story system.

## 6. Explore, categories, and communities

### Categories and tags

A category identifies a story's subject, such as Recipe, Song, Local History, or Language. The Add Story category field is typable, with a compact searchable suggestion list. An author can select a suggestion or enter a category. Category results query the backend; aliases connect some display categories to equivalent stored categories, for example Food and Recipe.

Tags provide additional keywords where supported by the stored story. A hashtag is not a community membership. A story reaches a community because it stores that community's ID, not merely because a user types its name into text.

### Community catalogue and following

Communities currently come from the curated backend catalogue. Memberships are stored in a separate collection. The catalogue supplies each community's ID, title, category, description, and image.

The elder opens a community and chooses Follow. A confirmation dialog explains the community and the effect on Following. Cancel makes no change. Confirm saves the membership and changes the button to Followed. Unfollowing requires a similar confirmation.

Member count is computed from actual saved membership records. Repeated follows do not create multiple memberships for the same user and community. The previous active-member count has been removed; the app does not currently measure online activity for this panel.

### Posting into a community

After following, the elder can use the community's Add Story action. The form opens with that community preset. In the general Add Story form, the community selector offers followed communities. The backend validates the selected community and membership when an individual elder story is posted.

The published story stores communityId and communityName. Community details query that ID, while a follower's Following feed uses the follower's memberships. The same published record can therefore appear in Home, its category results, and its community feed without creating separate copies.

The current flow exposes the Add Story action; following itself does not automatically open a second Add Story popup. The earlier requested extra popup should be treated as a possible future UX enhancement, not a completed behavior.

## 7. Add Story: all four sections

### Section 1: Required story details

The elder supplies a title, category, language, and original story content. Categories are typable with suggestions. Supported language choices are Tamil, Sinhala, and English.

The author can type, record audio, convert the saved recording to editable text, and listen to text through text-to-speech while composing. Convert Recording to Text uploads the saved M4A file to the authenticated backend transcription endpoint; it does not open a new microphone session. The backend sends the recording to Gemini for transcription, preserving the spoken language and wording. Add Story voice conversion, text reading, and story summaries use Gemini; other AI actions retain their existing OpenAI configuration. GEMINI_SUMMARY_MODEL configures summary generation, defaulting to gemini-3.5-flash-lite. Approval, storage, and preview selection remain the same.

Recording conversion and spoken story reading require internet access and GEMINI_API_KEY in backend/.env. VOICE_AI_PROVIDER=gemini selects Gemini conversion. GEMINI_TRANSCRIPTION_MODEL defaults to gemini-3.5-transcribe and GEMINI_TTS_MODEL defaults to gemini-3.8-flash-tts. Gemini recording uploads are limited to 14 MB to allow for base64 encoding within the provider request limit. Failed conversions preserve the recording for retry. Read Story requests WAV narration from the backend and plays it on the phone; Stop cancels playback or ignores an outstanding generation result. Review converted text before publishing. These provider integrations have mocked tests; live quality and language support require device testing with an active key. Story publication still requires storyText, and shared playback of published original recordings remains incomplete.

### Section 2: Optional context and media

The form includes location, community, a time-period choice, a banner image, and up to eight additional images. Time-period choices include childhood, young adulthood, many years ago, uncertainty, and Skip. Context helps a reader understand where and when a memory belongs.

Photos are uploaded to the backend and their returned paths are stored in the story. A banner supports discovery; additional images support detail and evidence. Location text is not yet an automatic link to a map place or geographic coordinates.

The people controller found in the form implementation is not currently part of the submitted story payload. It should not be represented as a reliably persisted people/attribution feature.

### Section 3: YATHRA AI Summary

The elder chooses Generate summary. The app submits the title, original story text, and selected language to the backend. The returned summary is editable. The elder can regenerate it, approve it with the review checkbox, or skip it.

The intended output is one or two source-faithful sentences, at most 700 characters. The original text is not replaced. The preview and original are stored separately.

If the title, language, or original story changes, the client invalidates its existing summary approval. A source fingerprint checks whether the approved summary still belongs to the current content. The backend also marks an existing summary outdated when the original changes without an explicit new summary decision.

Only an approved summary is used for a real feed preview. Skipping lets the elder publish without waiting for AI; the preview then comes from the original.

### Section 4: Review and publish

The author reviews the content and publishes. The story endpoint saves the original, context, image paths, community association, and any approved summary. The content-change signal lets relevant views refresh.

The individual form displays visibility choices, but the current Story schema/routes do not provide complete private/community-only access enforcement. Do not describe those choices as verified privacy controls. The individual form's Save Draft action currently shows a confirmation message without a persisted individual draft implementation. Collaborative Save Draft is different: it is stored in the workspace.

Audio currently stores a recording path, rather than a verified shared audio-upload pipeline. A local phone recording path is not sufficient for playback on another user's device.

## 8. Story details and original content

Story details preserves the elder's original text as the main content. It displays the title, language/category/context, available photos, and a gallery that can be opened and browsed.

An AI summary card exists conditionally in the elder detail screen, but its getter currently reads the map-based storyData input. Opening a detail screen with only a Story model does not consistently populate that card. The approved feed preview is implemented; consistent summary display across every detail route still needs work.

The elder detail screen currently includes local reactions, sample comments, local comment additions, and a local saved toggle. These do not persist as real social interactions in MongoDB. Its listen button currently reports that playback is unavailable or that no recording exists. The presence of the button is not a completed playback feature.

Translation and cultural explanation services exist elsewhere in the backend/youth experience. They should not be described as fully integrated elder detail-page controls unless that integration is separately completed.

## 9. My Connections and notifications

A youth chooses an elder and requests a connection. When a community is selected, the backend validates it and requires the requesting youth to follow it. A connection stores the participants and its community context.

The elder sees pending requests in Notifications or My Connections. Accepting permits the participants to chat and use the shared project workspace. Rejecting does not grant accepted-connection access. Requests and accepted relationships are different states; pending requests are not included in the profile's Connections total.

Only participants in an accepted connection may access its protected messages and workspace. Publishing a collaborative contribution requires the connected elder, not merely any user with an elder role.

## 10. Chat and assisted interviewing

The participants exchange text messages about a memory, recipe, ceremony, song, or other cultural topic. Messages are saved on the connection. The UI includes manual refresh; the current implementation should not be described as a verified real-time socket chat.

Suggest Questions asks for conversation starters based on community/topic and role. Follow-up Questions uses the latest conversation messages to suggest what to ask next. The backend returns three to five short, respectful questions.

Suggestions are optional prompts. The user chooses what to ask; generated questions are not automatically sent as the user's message. Their purpose is to help youth conduct a thoughtful interview and help elders recall context, origins, people, changes over time, and details worth preserving.

When the AI call fails, the client can show basic fallback questions. These are deterministic templates, such as asking how the tradition was first learned. They are useful assistance but are not generated by a model.

## 11. My Projects and collaborative publishing

An accepted connection provides a project context. A project can contain multiple workspace contributions, so a long collaboration can produce several stories rather than one overwritten draft.

Add Content now reuses the same Add Story form sections and fields. Project status and participant information remain outside that form. The community is carried from the project context and is locked in the shared editor. The workflow's draft and review controls remain the project controls; it does not independently publish through the individual story endpoint.

### Status transitions and responsibilities

| State | Meaning | Next action |
| --- | --- | --- |
| draft | Work is being prepared | Youth or elder saves permitted edits; youth sends for review |
| under_review | Youth has submitted the contribution | Connected elder edits, requests changes, or approves |
| changes_requested | Elder identified needed corrections | Youth revises and sends for review again |
| approved | Elder has accepted the contribution | Connected elder publishes |
| published | A Story record has been created | Open the published story |

Youth can edit drafts and contributions with changes requested. The elder can edit drafts or a contribution under review. Approved/published content is not treated as an unrestricted editable draft in this workflow.

The elder's review should check the original wording, factual and cultural context, category, language, photos, place/time context, and any summary. This is human review; it is not automatic AI certification of truth.

Publishing creates a Story record with the original workspace content, shared form context and media, contributors, connection reference, and community association. Original text is no longer built by automatically appending the legacy short-description and significance fields. Those legacy workspace fields are retained in storage, but the aligned form uses the story content as the published original.

For collaborative previews, the summary can be prepared in the shared form. A connected youth is allowed to request summary generation in an accepted collaboration. The elder's subsequent contribution review and approval remains the final publishing gate. There is no separate cryptographic or audited author-signature system for the summary checkbox.

## 12. Chat-to-story drafting: supported backend, incomplete current UI

The assistant backend supports chat-to-story. It reads up to the last 60 connection messages, labels youth and elder speakers, and asks for a title, description, content, and cultural significance. Only the connected youth may request this action, and both participants must have consented to use their chat.

Every newly sent message resets those consent flags. This prevents treating consent for an earlier conversation as automatically covering later messages.

However, the current frontend assistant calls found in the chat screen are question suggestions. There is no currently wired chat-to-story user action or complete consent-to-generated-draft route. This is a supported backend capability and a potential next integration, not a completed end-to-end elder feature.

If integrated later, the expected sequence is: obtain both consents, generate a draft, let youth edit it, save it as a workspace item, and submit it to the elder's existing review flow. AI must not bypass that review.

## 13. Profile and participation counts

The profile back arrow selects Home when the profile is opened as a shell tab. Edit Profile opens the elder editing sheet and saves to the backend. A successful save updates the displayed identity and shell name.

Contributions is the count of nondeleted published stories where the user is the publishing author or is included in contributors. A collaborative story is counted once for a qualifying user by the database query. Unpublished drafts and pending reviews are not contributions in this definition.

Connections is the number of accepted connection records involving that user. Under the current youth-requester/elder-receiver relationship model, this represents connected people. It does not count followed communities, pending requests, followers, or following.

My Projects appears above the connections panel and opens the existing workspace. Manage Connections opens the existing relationship page. The elder's recent-post preview now requests that user's own stories.

Some other profile insight panels still contain demonstration values or inactive actions. The change to real contribution/connection counts does not make every historical insight metric a live analytics feature.

## 14. Map section

The map lets the user inspect cultural locations, apply category and region filters, select markers, and open place details. Place details explain the selected location and show related stories and nearby places.

Currently, places and related story associations come from sample data. Related stories are resolved through the youth dummy-content store. Nearby behavior is partly simplified rather than a complete live geolocation service. An elder can inspect the map, while place saving is currently restricted in the detail screen according to role and uses local state.

There is no completed backend flow that automatically attaches an elder's newly posted story to a map marker using the story's location text. Using the approved summary in real related-story map previews is an intended extension, not current production behavior.

The map's value is spatial understanding: it can eventually connect cultural knowledge to places where it was practiced. It is not currently AI location inference or an AI-generated map.

## 15. AI usage: where, what, why, and advantage

| Capability | Where | Input and output | Purpose and advantage | Current status |
| --- | --- | --- | --- | --- |
| Story summary | Individual Add Story and shared project form | Title, original text, language → short summary | Helps readers judge relevance while preserving the original | Connected to generation, author review, storage, and real feed previews |
| Conversation starters | Accepted-connection chat | Community/topic, role → 3–5 questions | Reduces the difficulty of starting a cultural interview | Wired; basic template fallback exists |
| Follow-up questions | Accepted-connection chat | Last 12 messages → 3–5 questions | Encourages deeper context and fewer missed details | Wired; basic fallback exists |
| Chat-to-story | Assistant backend | Last 60 messages → structured draft | Could reduce manual organization of interviews | Backend and consent checks exist; current UI integration incomplete |
| Category/tags suggestions | Assistant backend | Title/content/context → category and tags | Could improve consistent discovery | Backend exists; old workspace suggestion control was removed during shared-form alignment |
| Story translation | Youth-oriented backend/service routes | Original and language pair → translation | Helps cross-language reading | Separate from current elder publishing/detail workflow |
| Cultural term explanation | Youth-oriented services | Term and context → explanation | Could help readers understand unfamiliar vocabulary | Separate feature; not an elder fact-checking system |
| Speech recognition | Add Story composition | Live microphone speech → editable text | Supports oral expression and reduces typing | Device/platform speech service; not the same as summary generation |
| Text-to-speech | Add Story composition | Current text and language → spoken output | Helps the elder review wording by listening | Device/plugin functionality; detail playback remains incomplete |

## 16. How the generative AI works technically

1. The user explicitly requests an AI action. The application does not generate a summary merely because the author typed a story.
2. Flutter sends an authenticated request to the YATHRA backend, including only the data needed by that action.
3. The backend validates the input and role. Collaboration actions also validate the connection and participant relationship. Chat-to-story additionally checks both consent flags.
4. The assistant prepares instructions: use the requested language, rely on supplied facts, avoid invented names/dates/procedures, flag uncertain details for elder confirmation, and treat supplied content as reference material rather than instructions.
5. The backend calls the configured OpenAI model through the Responses API. The API key stays in the backend configuration. The Flutter application does not need the provider key.
6. For the culture assistant, a strict JSON schema defines the response shape. A summary returns a summary string; question actions return a questions array; drafting returns named draft fields.
7. The backend parses the generated output. Summary length and other action-specific constraints are checked before returning the result.
8. Flutter displays the result for human use or editing. An approved summary is saved with the story; question suggestions are not automatically sent as messages.
9. Provider failures, missing configuration, rate limits, inaccessible models, malformed output, or timeouts return errors. Question UI may use template fallbacks. Summary UI allows retry or skip.

The provider call has a 30-second timeout. The summary client waits up to 40 seconds for its request. The model name is configurable through OPENAI_MODEL; the code does not establish a fixed model for every deployment.

The code sends store:false in its provider requests. This is a request setting, not a claim that no provider logs or other retention can exist. The application sends story/chat content to an external AI provider when those actions are used; a launch privacy notice should explain this accurately.

This implementation uses a configured general-purpose model with prompts and structured output. It does not show a custom-trained YATHRA model, fine-tuning pipeline, retrieval-augmented cultural archive, web fact verification, or autonomous AI moderation. JSON schema controls structure; it does not prove factual correctness. Prompt instructions reduce unwanted invention but cannot guarantee accuracy.

## 17. Summary lifecycle and data separation

The story stores storyText as the original, aiSummary as the optional preview, and summaryStatus as approved, skipped, or outdated. A summary must be approved and nonempty to become the preview. Editing the original without a new valid review invalidates that summary.

Example original: a long account of preparing a family dish, learning it from a grandmother, and sharing it during village celebrations.

Example approved preview: An elder remembers a family recipe and the village celebrations where it was prepared. The story explains how the knowledge passed between generations.

Readers see the preview below the title and open the original for full context. The preview is a reading aid, not a replacement record and not an independent claim of historical verification.

Desired consistency across community/category cards can reuse the same Story preview behavior. Summary display on every detail route and real map-related stories still needs completion, as described above.

## 18. Proposed novelty and contribution

The project's defensible novelty is the combination of an elder-led preservation workflow, youth collaboration, community-linked distribution, geographic discovery, and human-reviewed AI assistance. Summarization, chat, and maps individually are established techniques.

The strongest project-level contributions are:

1. Elder-controlled publication: youth documentation enters an explicit review and approval process before collaborative publication.
2. Preservation of original expression: the original story and an approved discovery preview remain separate.
3. Intergenerational interviewing support: AI questions guide a youth to explore cultural memories rather than simply asking for generic generated content.
4. Shared contribution structure: individual and collaborative contributions use the same form, supporting comparable story metadata.
5. Community-aware discovery: posting context and followed memberships control which stories enter Following.
6. A multilingual and geographically situated preservation direction: language choices and place discovery can help connect different readers to local knowledge, although map integration is still partial.

These are design contributions and candidate novelty claims. No literature review or competitor study was performed for this document. Do not claim YATHRA is the first, unique worldwide, patented, or scientifically proven to preserve culture better without evidence.

For an academic presentation, use: YATHRA combines elder-reviewed intergenerational documentation with optional AI-assisted interviewing and story previews, while retaining the contributor's original narrative.

## 19. Advantages and practical limits

For elders, the form offers typing and oral composition support; summaries can be skipped; cultural review remains human. For youth, guided questions can make interviews easier, and workspace review clarifies what is ready to publish. For readers, short previews and category/community organization reduce the effort required to discover relevant stories. For the development team, one shared content structure reduces differences between individual and collaborative posts.

Potential benefits should be validated with actual users. Claims about increased accuracy, engagement, accessibility, or preservation impact need user testing or measured results. AI may misrepresent a memory, lose nuance, or produce a fluent but unsupported sentence. Elder review, source preservation, editable outputs, and skip behavior are the present controls.

## 20. Worked example: preserving a family recipe

1. An elder follows Jaffna Cuisine after reading its description.
2. The elder opens Add Story from that community; the community is preset.
3. The elder enters the recipe title, chooses Recipe and Tamil, and writes the recipe with family memories.
4. The elder adds Jaffna, a childhood time period, a banner photo, and preparation photos.
5. The elder requests a summary, corrects a phrase, and checks approval. Alternatively, the elder skips it.
6. Publishing stores the original and preview separately in one Story record.
7. The story is discoverable through its community ID and matching category. A follower's Following request includes it.
8. A youth requests a connection to learn more. The elder accepts, and they exchange messages.
9. Suggested follow-up questions help the youth ask who taught the recipe and how it changed over time.
10. The youth creates a project contribution using the shared form, saves a real workspace draft, and sends it for review.
11. The elder requests a correction, receives the revised submission, approves, and publishes it.
12. The participants' published contribution counts reflect their authored/credited story. Their accepted relationship contributes to Connections.

This example describes the connected posting/review flow. It does not imply that the AI verifies recipe safety, that map placement happens automatically, or that the current local comments are shared server data.

## 21. Backend and database responsibilities

| Data | Storage responsibility | Reason |
| --- | --- | --- |
| User identity/profile | User model | Authentication, role, displayed identity |
| Original and approved summary | Story model | One canonical published record with separate preview |
| Community definitions | Curated JSON catalogue | Stable community IDs and descriptions |
| Following/member counts | CommunityMembership model | Persistent and idempotent membership |
| Requests, participants, chat, project content | Connection model and workspaceItems | Relationship access and collaborative review history/state |
| Image files | Backend uploads directory, with paths in stories/workspaces | Media associated with contributions |

For launch, phones connect to a deployed backend, and the backend connects to the chosen shared MongoDB database. Database credentials remain backend configuration. A common database alone does not synchronize local upload folders across developer laptops; media needs a shared production storage arrangement.

Changing MONGODB_URI changes the destination database, not the existing data. Account and story migration must be performed deliberately if the team consolidates databases. The current development Android app uses localhost through USB port forwarding; launch requires a deployed backend URL.

## 22. Launch completion priorities

1. Replace or clearly isolate Home, youth, map, social, and insight demonstration data.
2. Implement persistent likes, comments, bookmarks, and the relevant permission checks.
3. Complete audio uploading/shared playback and resolve recording-only publishing requirements.
4. Implement actual individual draft persistence; retain the already persisted workspace drafts.
5. Enforce visibility/access choices in the backend before presenting private publishing as supported.
6. Make reviewed summary display consistent in all story details and previews.
7. Link real stories to real map places with an explicit place ID/location workflow.
8. Wire chat-to-story consent and UI if that feature is included in the launch scope.
9. Add shared production media storage, deploy the backend, and configure the app's production API URL.
10. Validate language support, elder usability, summary fidelity, and failure recovery with representative users.

These priorities describe remaining gaps. Recording-to-text conversion has since been connected to backend transcription; shared audio playback remains separate.

## 23. Source guide for developers

The following repository files ground this document:

- frontend/lib/pages/youth_hub_shell.dart: role-based shell and tab navigation.
- frontend/lib/widgets/home_header.dart: header, projects/connections menu, and search heading.
- frontend/lib/pages/elder/elder_home_page.dart: elder feed, refresh, Following requests, and sample cards.
- frontend/lib/pages/elder/share_story_page.dart: shared four-section authoring form, speech tools, media, summary review.
- frontend/lib/pages/elder/story_details_page.dart: elder detail rendering, gallery, and current local interactions.
- frontend/lib/pages/elder/elder_profile_page.dart and elder_edit_profile_sheet.dart: elder profile, counts, and editing.
- frontend/lib/pages/community_details_page.dart and explore_page.dart: communities, membership actions, category discovery.
- frontend/lib/pages/culture_connect_pages.dart: requests, notifications, chat, project list, and review controls.
- frontend/lib/pages/map/cultural_map_page.dart and cultural_place_detail_page.dart: current map and sample place relationships.
- frontend/lib/models/story.dart and widgets/social_story_card.dart: approved-preview selection and feed card behavior.
- backend/src/routes/authRoutes.js: profile editing and actual participation counts.
- backend/src/routes/storyRoutes.js and models/Story.js: story persistence, ownership, filtering, and summary fields.
- backend/src/routes/communityRoutes.js and models/CommunityMembership.js: following and real member counts.
- backend/src/routes/connectionRoutes.js and models/Connection.js: workspace storage and review/publication transitions.
- backend/src/routes/aiRoutes.js: story-summary authorization and endpoint.
- backend/src/routes/transcriptionRoutes.js: authenticated saved-recording upload and provider transcription and story narration.
- backend/src/services/geminiVoiceService.js: Gemini audio conversion and WAV narration.
- backend/src/controllers/cultureContentAssistantController.js: assistant action permissions, context selection, and consent.
- backend/src/services/cultureContentAssistantService.js: provider request, instructions, strict schemas, and errors.
- frontend/lib/services/culture_assistant_fallback.dart: deterministic assistance used when applicable.

All provider behavior described here refers to how this repository calls the provider. No live AI quality benchmark or external novelty review was performed while preparing the document.
