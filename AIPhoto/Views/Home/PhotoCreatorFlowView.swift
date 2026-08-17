import PhotosUI
import SwiftUI
import UIKit

enum PhotoTemplateCategory: String, CaseIterable, Identifiable {
    case trending
    case new
    case cartoons
    case fifaWorldCup
    case cinematic
    case royalLuxury
    case aroundWorld
    case superpowers
    case futureJobs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trending: "🔥 Trending"
        case .new: "⚡ New"
        case .cartoons: "🎨 Cartoons"
        case .fifaWorldCup: "⚽ FIFA World Cup"
        case .cinematic: "🎬 Cinematic"
        case .royalLuxury: "👑 Royal & Luxury"
        case .aroundWorld: "🌍 Around the World"
        case .superpowers: "⚡ Superpowers"
        case .futureJobs: "🚀 Future Jobs"
        }
    }
}

struct PhotoCreationRequest {
    let sourceImageData: Data?
    let styleReferenceImageData: Data?
    let template: PhotoTemplateStyle?
    let prompt: String
}

enum PhotoTemplateBadge: Equatable {
    case none
    case trend
    case new
}

struct PhotoTemplateStyle: Identifiable, Equatable {
    let title: String
    let asset: String
    let isPrecomposed: Bool
    let category: PhotoTemplateCategory

    init(
        title: String,
        asset: String,
        isPrecomposed: Bool,
        category: PhotoTemplateCategory = .cartoons
    ) {
        self.title = title
        self.asset = asset
        self.isPrecomposed = isPrecomposed
        self.category = category
    }

    var id: String { asset }

    var prompt: String {
        PhotoStylePrompt.prompt(for: asset)
    }

    static let cartoonTemplates: [PhotoTemplateStyle] = [
        .init(title: "Simson Style", asset: "cartoon_category_simson", isPrecomposed: true),
        .init(title: "Pixar Style", asset: "cartoon_category_pixar", isPrecomposed: true),
        .init(title: "Disney Style", asset: "cartoon_category_disney", isPrecomposed: true),
        .init(title: "Total Drama Style", asset: "cartoon_category_total_drama", isPrecomposed: true),
        .init(title: "Griffin Style", asset: "cartoon_category_griffin", isPrecomposed: true),
        .init(title: "Rick And Morty ...", asset: "cartoon_category_rick_morty", isPrecomposed: true),
        .init(title: "Adventure time ...", asset: "cartoon_category_adventure_time", isPrecomposed: true),
        .init(title: "American dad Style", asset: "cartoon_category_american_dad", isPrecomposed: true)
    ]

    static let trendingTemplates: [PhotoTemplateStyle] = [
        .init(title: "Video Avatar", asset: "fifa_category_video_avatar", isPrecomposed: true, category: .trending),
        .init(title: "Win CUP", asset: "fifa_category_win_cup", isPrecomposed: true, category: .trending),
        .init(title: "Simson Style", asset: "cartoon_category_simson", isPrecomposed: true, category: .trending)
    ]

    static let newTemplates: [PhotoTemplateStyle] = [
        .init(title: "3D Character", asset: "new_category_3d_character", isPrecomposed: true, category: .new),
        .init(title: "Avatar Style", asset: "new_category_avatar_style", isPrecomposed: true, category: .new),
        .init(title: "Doll", asset: "new_category_doll", isPrecomposed: true, category: .new),
        .init(title: "Goal", asset: "fifa_category_goal_new", isPrecomposed: true, category: .new)
    ]

    static let fifaTemplates: [PhotoTemplateStyle] = [
        .init(title: "Video Avatar", asset: "fifa_category_video_avatar", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Team symbol", asset: "fifa_category_team_symbol", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Goal", asset: "fifa_category_goal_new", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Run", asset: "fifa_category_run", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Neon run", asset: "fifa_category_neon_run", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Win CUP", asset: "fifa_category_win_cup", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Dribbling", asset: "fifa_category_dribbling", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Goal", asset: "fifa_category_goal", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Dream", asset: "fifa_category_dream", isPrecomposed: true, category: .fifaWorldCup),
        .init(title: "Dribbling", asset: "fifa_category_dribbling_alt", isPrecomposed: false, category: .fifaWorldCup),
        .init(title: "Goal", asset: "fifa_category_goal_alt", isPrecomposed: false, category: .fifaWorldCup),
        .init(title: "Win CUP", asset: "fifa_category_win_cup_alt", isPrecomposed: false, category: .fifaWorldCup)
    ]

    static let cinematicTemplates: [PhotoTemplateStyle] = [
        .init(title: "Cyberpunk Hero", asset: "cinematic_cyberpunk_hero", isPrecomposed: false, category: .cinematic),
        .init(title: "Space Commander", asset: "cinematic_space_commander", isPrecomposed: false, category: .cinematic),
        .init(title: "Mafia Boss", asset: "cinematic_mafia_boss", isPrecomposed: false, category: .cinematic),
        .init(title: "Secret Agent", asset: "cinematic_secret_agent", isPrecomposed: false, category: .cinematic),
        .init(title: "Apocalypse Survivor", asset: "cinematic_apocalypse_survivor", isPrecomposed: false, category: .cinematic)
    ]

    static let royalLuxuryTemplates: [PhotoTemplateStyle] = [
        .init(title: "King", asset: "royal_luxury_king", isPrecomposed: false, category: .royalLuxury),
        .init(title: "Queen", asset: "royal_luxury_queen", isPrecomposed: false, category: .royalLuxury),
        .init(title: "Billionaire", asset: "royal_luxury_billionaire", isPrecomposed: false, category: .royalLuxury),
        .init(title: "CEO Magazine Cover", asset: "royal_luxury_ceo_cover", isPrecomposed: false, category: .royalLuxury),
        .init(title: "Red Carpet", asset: "royal_luxury_red_carpet", isPrecomposed: false, category: .royalLuxury)
    ]

    static let aroundWorldTemplates: [PhotoTemplateStyle] = [
        .init(title: "Tokyo Nights", asset: "around_world_tokyo_nights", isPrecomposed: false, category: .aroundWorld),
        .init(title: "Santorini Vacation", asset: "around_world_santorini", isPrecomposed: false, category: .aroundWorld),
        .init(title: "Dubai Luxury", asset: "around_world_dubai_luxury", isPrecomposed: false, category: .aroundWorld),
        .init(title: "Paris Café", asset: "around_world_paris_cafe", isPrecomposed: false, category: .aroundWorld),
        .init(title: "Northern Lights", asset: "around_world_northern_lights", isPrecomposed: false, category: .aroundWorld)
    ]

    static let superpowersTemplates: [PhotoTemplateStyle] = [
        .init(title: "Fire Master", asset: "superpowers_fire_master", isPrecomposed: false, category: .superpowers),
        .init(title: "Ice Royal", asset: "superpowers_ice_royal", isPrecomposed: false, category: .superpowers),
        .init(title: "Lightning Hero", asset: "superpowers_lightning_hero", isPrecomposed: false, category: .superpowers),
        .init(title: "Shadow Assassin", asset: "superpowers_shadow_assassin", isPrecomposed: false, category: .superpowers),
        .init(title: "Nature Guardian", asset: "superpowers_nature_guardian", isPrecomposed: false, category: .superpowers)
    ]

    static let futureJobsTemplates: [PhotoTemplateStyle] = [
        .init(title: "AI Engineer", asset: "future_jobs_ai_engineer", isPrecomposed: false, category: .futureJobs),
        .init(title: "Formula Racing Driver", asset: "future_jobs_formula_driver", isPrecomposed: false, category: .futureJobs),
        .init(title: "Professional Gamer", asset: "future_jobs_professional_gamer", isPrecomposed: false, category: .futureJobs),
        .init(title: "Astronaut", asset: "future_jobs_astronaut", isPrecomposed: false, category: .futureJobs),
        .init(title: "Master Chef", asset: "future_jobs_master_chef", isPrecomposed: false, category: .futureJobs)
    ]

    static func templates(for category: PhotoTemplateCategory) -> [PhotoTemplateStyle] {
        switch category {
        case .trending: trendingTemplates
        case .new: newTemplates
        case .cartoons: cartoonTemplates
        case .fifaWorldCup: fifaTemplates
        case .cinematic: cinematicTemplates
        case .royalLuxury: royalLuxuryTemplates
        case .aroundWorld: aroundWorldTemplates
        case .superpowers: superpowersTemplates
        case .futureJobs: futureJobsTemplates
        }
    }

    static func previewTemplates(for category: PhotoTemplateCategory) -> [PhotoTemplateStyle] {
        let categoryTemplates = templates(for: category)

        if category == .new {
            let featuredAssets = [
                "new_category_3d_character",
                "new_category_avatar_style",
                "fifa_category_goal_new"
            ]
            return featuredAssets.compactMap { asset in
                categoryTemplates.first { $0.asset == asset }
            }
        }

        if category == .fifaWorldCup {
            let featuredAssets = [
                "fifa_category_video_avatar",
                "fifa_category_win_cup",
                "fifa_category_goal_new"
            ]
            return featuredAssets.compactMap { asset in
                categoryTemplates.first { $0.asset == asset }
            }
        }

        return Array(categoryTemplates.prefix(3))
    }

    static func badge(
        for template: PhotoTemplateStyle,
        at index: Int,
        in category: PhotoTemplateCategory
    ) -> PhotoTemplateBadge {
        switch category {
        case .trending:
            return embeddedTrendBadgeAssets.contains(template.asset) ? .none : .trend
        case .cartoons:
            return index < 2 ? .trend : .none
        case .new, .fifaWorldCup, .cinematic, .royalLuxury, .aroundWorld, .superpowers, .futureJobs:
            return .none
        }
    }

    private static let embeddedTrendBadgeAssets: Set<String> = [
        "fifa_category_video_avatar",
        "fifa_category_win_cup"
    ]

    static func resolved(
        title: String,
        asset: String,
        category: PhotoTemplateCategory
    ) -> PhotoTemplateStyle {
        if let template = templates(for: category).first(where: { $0.title == title }) {
            return template
        }

        let mappedTitle: String?

        switch asset {
        case "photo_simson", "photo_creator_simson":
            mappedTitle = "Simson Style"
        case "photo_pixar", "photo_creator_pixar":
            mappedTitle = "Pixar Style"
        case "photo_cartoon_princess", "photo_creator_disney":
            mappedTitle = "Disney Style"
        case "photo_creator_total_drama":
            mappedTitle = "Total Drama Style"
        case "photo_creator_griffin":
            mappedTitle = "Griffin Style"
        case "photo_creator_rick_morty":
            mappedTitle = "Rick And Morty ..."
        case "photo_category_adventure_time":
            mappedTitle = "Adventure time ..."
        case "photo_category_american_dad":
            mappedTitle = "American dad Style"
        case "photo_3d_character":
            mappedTitle = "3D Character"
        case "photo_avatar_style":
            mappedTitle = "Avatar Style"
        case "photo_doll":
            mappedTitle = "Doll"
        default:
            mappedTitle = nil
        }

        if let mappedTitle,
           let template = templates(for: category).first(where: { $0.title == mappedTitle }) {
            return template
        }

        return .init(title: title, asset: asset, isPrecomposed: false, category: category)
    }

    func inCategory(_ category: PhotoTemplateCategory) -> PhotoTemplateStyle {
        .init(
            title: title,
            asset: asset,
            isPrecomposed: isPrecomposed,
            category: category
        )
    }
}

private enum PhotoStylePrompt {
    private static let preservation = """
    Use only the exact uploaded crop as the identity and composition source. Preserve its camera angle, framing, visible body area, pose, and edge crop exactly. Do not zoom out, extend the canvas, reconstruct, invent, or reveal any face, head, limb, clothing, or background that is outside the uploaded crop. If the crop intentionally contains only hands, legs, clothing, an object, or another partial subject, transform only that visible content. Apply the visual transformation consistently to every visible element. Produce one polished image with clean anatomy and professional detail. No text, captions, logos, watermarks, duplicate people, extra fingers, extra limbs, facial distortion, blur, or low-resolution artifacts.
    """

    static func prompt(for asset: String) -> String {
        let direction: String

        switch asset {
        case "cartoon_category_simson", "photo_simson":
            direction = "Transform the subject into a classic yellow-skinned prime-time animated sitcom character: bold black outlines, simplified expressive features, flat cel colors, clean two-dimensional shading, playful suburban scenery, and a warm pastel evening palette."
        case "cartoon_category_pixar", "photo_pixar":
            direction = "Transform the subject into a premium cinematic 3D family-animation character: appealing stylized proportions, expressive eyes, soft rounded facial forms, realistic hair strands, subtle subsurface skin shading, rich fabric detail, warm global illumination, and shallow depth of field."
        case "cartoon_category_disney", "photo_cartoon_princess", "photo_creator_disney":
            direction = "Transform the subject into an elegant modern fairytale-princess portrait: graceful stylized features, luminous eyes, detailed flowing costume, soft romantic colors, delicate sparkles, enchanted garden atmosphere, painterly cinematic lighting, and refined storybook polish."
        case "cartoon_category_total_drama", "photo_creator_total_drama":
            direction = "Transform the subject into an energetic angular two-dimensional reality-cartoon character: exaggerated sharp silhouettes, long expressive limbs, heavy clean outlines, flat cel shading, graphic shapes, rebellious wardrobe details, and a dramatic saturated sunset backdrop."
        case "cartoon_category_griffin", "photo_creator_griffin":
            direction = "Transform the subject into a clean irreverent family-sitcom cartoon character: simple geometric anatomy, crisp dark outlines, flat solid colors, minimal cel shading, restrained facial detail, humorous expression, and a bright suburban neighborhood background."
        case "cartoon_category_rick_morty", "photo_creator_rick_morty":
            direction = "Transform the subject into a surreal adult sci-fi cartoon character: loose slightly wobbly ink contours, eccentric facial construction, flat acid-toned colors, portal glow, strange alien scenery, playful cosmic details, and chaotic hand-drawn energy."
        case "cartoon_category_adventure_time", "photo_category_adventure_time":
            direction = "Transform the subject into a whimsical minimalist fantasy-cartoon hero: rounded geometry, simple expressive face, smooth black outlines, soft candy colors, imaginative costume, quirky magical environment, and charming hand-drawn simplicity."
        case "cartoon_category_american_dad", "photo_category_american_dad":
            direction = "Transform the subject into a polished adult animated-sitcom character: crisp controlled outlines, simplified anatomy, flat cel colors, clean facial planes, subtle comic exaggeration, and a bright graphic background with a confident television-animation finish."
        case "new_category_3d_character", "photo_3d_character":
            direction = "Transform the subject into a vibrant stylized 3D fashion-game avatar: glossy sculpted features, large expressive eyes, detailed colorful hair, trendy accessories, premium toy-like materials, neon heart accents, magenta and violet lighting, and a playful high-energy beauty render."
        case "new_category_avatar_style", "photo_avatar_style":
            direction = "Transform the subject into a photorealistic blue alien humanoid from a lush tropical world: elegant elongated proportions, detailed cyan skin with subtle bioluminescent markings, expressive golden eyes, braided hair, handcrafted island clothing, palm trees, bright sky, and cinematic natural lighting."
        case "new_category_doll", "photo_doll":
            direction = "Transform the subject into a premium collectible gothic fashion doll displayed inside a realistic retail blister package: carefully sculpted likeness, tailored dark outfit, miniature themed accessories, dramatic product lighting, glossy transparent plastic, and a sophisticated mysterious presentation."
        case "fifa_category_video_avatar":
            direction = "Transform the subject into a futuristic professional football broadcast avatar: centered head-and-shoulders portrait, dark athletic jersey, cool cyan holographic frame, premium sports statistics HUD, neon blue edge lighting, sharp studio detail, and an elite esports broadcast aesthetic."
        case "fifa_category_team_symbol":
            direction = "Transform the subject into a majestic symbolic football-club mascot while retaining recognizable facial character: powerful white-lion styling, heroic stance on a stadium pitch, intense expression, dramatic floodlights, fireworks, atmospheric mist, and epic photorealistic sports-poster lighting."
        case "fifa_category_goal_new":
            direction = "Transform the subject into an elite footballer executing an acrobatic ball control at sunset: dynamic full-body pose, modern blue kit, suspended football, flying turf particles, packed stadium, orange rim light, cinematic sports photography, and crisp high-speed action detail."
        case "fifa_category_run":
            direction = "Transform the subject into a world-class footballer sprinting directly toward camera: blue number-ten kit, powerful athletic motion, realistic fabric and muscle detail, stadium crowd bokeh, shallow depth of field, natural field lighting, and premium editorial sports photography."
        case "fifa_category_neon_run":
            direction = "Transform the subject into a footballer making a dramatic night run with the ball: dark blue stadium, vivid electric-blue energy trail circling the athlete, cinematic contrast, sharp motion detail, glowing particles, and a polished supernatural sports-advertising look."
        case "fifa_category_win_cup":
            direction = "Transform the subject into a triumphant football champion celebrating on the pitch: iconic striped club kit, arms spread wide, joyful expression, bright stadium lights, cheering crowd, realistic sweat and fabric, cinematic depth, and an emotionally powerful victory photograph."
        case "fifa_category_dribbling":
            direction = "Transform the subject into an elite footballer performing a precise dribble in a vibrant green stadium: dynamic athletic posture, white-and-green kit, ball under close control, dramatic floodlights, floating turf particles, deep perspective, and high-end sports campaign realism."
        case "fifa_category_goal":
            direction = "Transform the subject into a golden-uniform football star controlling a metallic gold ball in mid-air: athletic full-body movement, warm backlit stadium, flying sparks and dust, dramatic low camera angle, crisp action freeze, and premium cinematic sports-poster detail."
        case "fifa_category_dream":
            direction = "Transform the subject into a young football prodigy living a magical stadium dream: colorful classic kit, focused ball control, flowing green cape shaped like a tactics board, glowing pitch markings, golden particles, aurora sky, and inspirational cinematic fantasy realism."
        case "fifa_category_dribbling_alt":
            direction = "Transform the subject into a victorious football captain lifting a large silver trophy: dark championship kit, dense red celebration smoke, stadium atmosphere, strong centered pose, sparkling metal reflections, dramatic backlight, and an iconic high-end victory campaign image."
        case "fifa_category_goal_alt":
            direction = "Transform the subject into a legendary football manager or club icon posed behind multiple European-style silver trophies: tailored navy suit, composed confident expression, warm premium portrait lighting, elegant neutral background, realistic polished metal, and prestigious editorial photography."
        case "fifa_category_win_cup_alt":
            direction = "Transform the subject into a charismatic anthropomorphic big-cat football mascot while retaining recognizable personality: spotted feline head, black-and-white club jersey, upright human pose, stadium background, colorful victory confetti, sharp fur detail, and playful photorealistic sports advertising."
        case "cinematic_cyberpunk_hero":
            direction = "Transform the subject into a cinematic cyberpunk hero in a sleek dark futuristic jacket: rain-slick neon megacity alley, subtle facial cybernetics, magenta and cyan rim lighting, wet reflections, atmospheric haze, intense story-driven expression, shallow depth of field, and premium photorealistic science-fiction detail."
        case "cinematic_space_commander":
            direction = "Transform the subject into a poised deep-space commander wearing a refined black futuristic uniform on a starship bridge: planet and stars beyond a panoramic window, cool blue instrument glow, warm facial key light, calm authority, cinematic depth, and premium photorealistic science-fiction production design."
        case "cinematic_mafia_boss":
            direction = "Transform the subject into an elegant cinematic crime-family boss seated in a dark leather chair: tailored charcoal suit, richly appointed private club, polished wood and chandelier bokeh, low-key amber lighting, subtle atmospheric haze, composed intimidating gaze, and sophisticated non-violent crime-drama realism."
        case "cinematic_secret_agent":
            direction = "Transform the subject into a stylish cinematic secret agent: perfectly tailored black suit, dark sunglasses and discreet earpiece, high-rise balcony above a modern city at night, cool skyline bokeh, crisp rim light, controlled confident posture, and premium photorealistic espionage-thriller detail."
        case "cinematic_apocalypse_survivor":
            direction = "Transform the subject into a resilient cinematic apocalypse survivor: layered weathered practical clothing, dusty but recognizable face, ruined urban avenue, wind-blown smoke and debris, dramatic overcast sky with warm sunlight breaking through, determined expression, and grounded non-graphic survival-film realism."
        case "royal_luxury_king":
            direction = "Transform the subject into a dignified modern king seated before an ornate throne: deep burgundy ceremonial tailoring with tasteful gold embroidery and white fur trim, refined crown, warm palace window light, rich dark wood, commanding calm gaze, and believable high-end royal portrait photography."
        case "royal_luxury_queen":
            direction = "Transform the subject into a poised modern queen in an ivory couture gown: intricate beadwork, refined gold crown and heirloom jewelry, grand palace interior, soft golden window light, subtle candle bokeh, serene confident expression, and luminous luxury editorial realism."
        case "royal_luxury_billionaire":
            direction = "Transform the subject into a self-assured billionaire entrepreneur: open-collar black tuxedo, sculptural chair inside a glass penthouse, dramatic skyline at dusk, discreet premium accessories without brands, warm interior accents, cool city light, modern power, and sophisticated luxury editorial photography."
        case "royal_luxury_ceo_cover":
            direction = "Transform the subject into a charismatic CEO photographed for a premium business magazine cover: perfectly tailored dark suit, minimalist architectural office, direct confident gaze, crisp studio key light, subtle warm rim light, clean negative space, polished leadership presence, and no printed text or logos."
        case "royal_luxury_red_carpet":
            direction = "Transform the subject into a glamorous red-carpet guest in elegant metallic couture evening wear: poised smile, crimson carpet, photographers and flash bulbs softly blurred behind, flattering warm key light, sparkling highlights, sophisticated high-fashion realism, and no event branding."
        case "around_world_tokyo_nights":
            direction = "Place the subject on a rain-slick pedestrian street in contemporary Tokyo at night: stylish layered fashion, vibrant lantern and neon shapes with no readable text, cyan, magenta and warm red reflections, gentle rain, energetic city bokeh, cinematic shallow depth of field, and premium travel photography."
        case "around_world_santorini":
            direction = "Place the subject on a whitewashed Santorini terrace overlooking cobalt domes and the Aegean sea at sunset: elegant flowing summer outfit, luminous golden-hour backlight, white and blue palette, soft sea haze, relaxed joyful expression, and premium photorealistic travel editorial styling."
        case "around_world_dubai_luxury":
            direction = "Place the subject on a modern Dubai boulevard beside an elegant unbranded violet supercar: futuristic skyline, tailored evening fashion, warm sunset reflections, refined purple, gold and charcoal palette, confident premium lifestyle mood, and photorealistic luxury travel-campaign detail."
        case "around_world_paris_cafe":
            direction = "Place the subject at a classic Paris sidewalk café with a coffee cup: chic beret and tailored camel coat, Eiffel Tower softly visible in the distance, warm café glow balanced with soft overcast morning light, muted cream and slate palette, and natural sophisticated street-editorial photography."
        case "around_world_northern_lights":
            direction = "Place the subject in a snowy Arctic valley beneath vivid green and blue northern lights: premium dark winter clothing, distant mountains, visible breath, face naturally illuminated by aurora and moonlit snow, awestruck composed expression, and cinematic photorealistic expedition photography."
        case "superpowers_fire_master":
            direction = "Transform the subject into an original fire master wearing a dark textured coat: both hands surrounded by controlled swirling flames, ember particles and subtle heat distortion, intense orange firelight against deep black, focused expression, anatomically natural hands, and premium photorealistic elemental-hero cinema."
        case "superpowers_ice_royal":
            direction = "Transform the subject into an original ice monarch: elegant crystalline crown, frost-detailed ceremonial armor, vast glacial palace, delicate snow particles, luminous blue-white reflections, cool silver palette, calm commanding gaze, and ethereal photorealistic fantasy-cinema detail."
        case "superpowers_lightning_hero":
            direction = "Transform the subject into an original lightning hero in a matte-black technical suit with subtle electric-blue circuitry: controlled lightning arcing around the body, luminous eyes, deep storm clouds, electric flashes, powerful silhouette, and photorealistic cinematic superhero detail without emblems."
        case "superpowers_shadow_assassin":
            direction = "Transform the subject into an original shadow assassin and stealth guardian: layered matte-black hooded clothing, lower face partially covered while recognizable eyes remain clear, moonlit mist, smoky shadow energy, silver highlights, watchful controlled presence, and non-violent dark-fantasy photorealism."
        case "superpowers_nature_guardian":
            direction = "Transform the subject into a noble nature guardian: elegant organic armor woven from leaves, bark and subtle gold, ancient enchanted woodland, a calm deer nearby, living vines, fireflies, soft green-gold sunbeams, gentle confident expression, and lush photorealistic fantasy-cinema detail."
        case "future_jobs_ai_engineer":
            direction = "Transform the subject into an aspirational AI engineer in a modern research studio: refined smart-casual clothing and clear glasses, transparent holographic neural-network visualizations, tasteful robotic components, clean cyan and white lab light, focused confident expression, and believable photorealistic technology editorial detail with no readable interface text."
        case "future_jobs_formula_driver":
            direction = "Transform the subject into an elite Formula racing driver in a professional pit lane: original unbranded black and deep-red fireproof suit, helmet held naturally at the side, sleek generic open-wheel race car behind, dramatic circuit light, determined expression, and premium photorealistic motorsport campaign styling."
        case "future_jobs_professional_gamer":
            direction = "Transform the subject into a professional esports competitor at a premium gaming station: tasteful dark hoodie and headset, violet, blue and pink monitor glow, trophy silhouette and arena lights behind, natural hands near the keyboard, focused confident expression, and polished photorealistic esports editorial detail."
        case "future_jobs_astronaut":
            direction = "Transform the subject into an astronaut on the lunar surface: technically believable unbranded white exploration suit, helmet visor raised so the recognizable face is clear, Earth suspended in black space, crisp sunlight, cool lunar shadows, calm courage, and cinematic scientific photorealism without flags or agency marks."
        case "future_jobs_master_chef":
            direction = "Transform the subject into a master chef in an elegant unbranded white jacket: plating a refined restaurant dish in a warm open kitchen, natural hands, subtle steam, pendant-light highlights, rich dark culinary bokeh, composed concentration, and premium photorealistic food-editorial photography."
        case "photo_bratz":
            direction = "Transform the subject into a glamorous stylized fashion-doll character: oversized almond eyes, glossy lips, smooth sculpted skin, long detailed hair, fashionable pastel outfit, cute accessories, polished 3D materials, beauty lighting, and a confident editorial pose."
        default:
            direction = "Transform the subject to closely match the supplied style-reference image, including its character design language, color palette, materials, lighting, rendering technique, wardrobe treatment, and background atmosphere."
        }

        return direction + "\n\n" + preservation
    }
}

struct PhotoCategoriesView: View {
    let initialCategory: PhotoTemplateCategory
    var onBack: () -> Void = {}
    var onSelectTemplate: (PhotoTemplateStyle) -> Void = { _ in }

    @State private var selectedCategory: PhotoTemplateCategory

    init(
        initialCategory: PhotoTemplateCategory,
        onBack: @escaping () -> Void = {},
        onSelectTemplate: @escaping (PhotoTemplateStyle) -> Void = { _ in }
    ) {
        self.initialCategory = initialCategory
        self.onBack = onBack
        self.onSelectTemplate = onSelectTemplate
        _selectedCategory = State(initialValue: initialCategory)
    }

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background
                    .ignoresSafeArea()

                header

                categoryPicker
                    .position(x: 196.5, y: layout.y(135))

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(170), spacing: 16),
                            GridItem(.fixed(170), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(PhotoTemplateStyle.templates(for: selectedCategory)) { template in
                            Button {
                                onSelectTemplate(template)
                            } label: {
                                categoryCard(template)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 170, height: 220)
                            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .frame(
                    width: 356,
                    height: max(220, layout.canvasHeight - layout.y(164) - 18)
                )
                .position(
                    x: 196.5,
                    y: (layout.y(164) + layout.canvasHeight - 18) / 2
                )

                HomeIndicatorReplica()
                    .position(x: 196.5, y: layout.homeIndicatorY)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 108)

            Button(action: onBack) {
                Image("app_btn_back")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .position(x: 34, y: 72)

            Text(selectedCategory.title)
                .font(AITheme.Typography.sfProDisplay(20, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: 275, alignment: .leading)
                .position(x: 205, y: 72)

            StatusBarReplica()
                .position(x: 196.5, y: 27)
        }
        .frame(width: 393, height: 108)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(PhotoTemplateCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.title)
                            .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background {
                                if selectedCategory == category {
                                    Capsule().fill(AITheme.primaryGradient)
                                } else {
                                    Capsule().fill(Color.white.opacity(0.04))
                                }
                            }
                            .overlay {
                                if selectedCategory != category {
                                    Capsule()
                                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(width: 393, height: 42)
    }

    private func categoryCard(_ template: PhotoTemplateStyle) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(template.asset)
                .resizable()
                .scaledToFill()
                .frame(width: 170, height: 220)

            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            Text(template.title)
                .font(AITheme.Typography.sfProDisplay(13, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .padding(12)
        }
        .frame(width: 170, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PhotoCreatorFlowView: View {
    @Binding var selectedTemplate: PhotoTemplateStyle
    var creationMode: AICreationMode = .photo
    @Binding var videoQuality: VideoGenerationQuality
    var onBack: () -> Void = {}
    var onSeeAll: () -> Void = {}
    var onCreate: (PhotoCreationRequest) -> Void = { _ in }

    init(
        selectedTemplate: Binding<PhotoTemplateStyle>,
        creationMode: AICreationMode = .photo,
        videoQuality: Binding<VideoGenerationQuality> = .constant(.p720),
        onBack: @escaping () -> Void = {},
        onSeeAll: @escaping () -> Void = {},
        onCreate: @escaping (PhotoCreationRequest) -> Void = { _ in }
    ) {
        _selectedTemplate = selectedTemplate
        self.creationMode = creationMode
        _videoQuality = videoQuality
        self.onBack = onBack
        self.onSeeAll = onSeeAll
        self.onCreate = onCreate
    }

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var showsSourceDialog = false
    @State private var showsPhotoLibrary = false
    @State private var showsCamera = false
    @State private var showsPhotoEditor = false
    @State private var isCropping = false
    @State private var cropScale: CGFloat = 1
    @State private var committedCropScale: CGFloat = 1
    @State private var cropOffset: CGSize = .zero
    @State private var committedCropOffset: CGSize = .zero
    @State private var cropRotation: Angle = .zero
    @State private var committedCropRotation: Angle = .zero

    private let cropViewportSide: CGFloat = 345

    private var selectedImage: UIImage? {
        guard let selectedPhotoData else { return nil }
        return UIImage(data: selectedPhotoData)
    }

    private var templates: [PhotoTemplateStyle] {
        let categoryTemplates = PhotoTemplateStyle.templates(for: selectedTemplate.category)
        if categoryTemplates.contains(selectedTemplate) {
            return categoryTemplates
        }
        return [selectedTemplate] + categoryTemplates
    }

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background.ignoresSafeArea()
                creatorTopBar

                if layout.isCompactHeight {
                    compactCreatorContent(layout: layout)
                } else {
                    if let selectedImage {
                        selectedPhotoPreview(
                            selectedImage,
                            side: cropViewportSide
                        )
                        .position(x: 196.5, y: 296.5)
                        templateSection(
                            layout: layout,
                            titleY: 503.5,
                            listY: 611
                        )
                    } else {
                        uploadPhotoButton
                            .position(x: 196, y: 207)
                        templateSection(layout: layout, titleY: 323.5, listY: 432)
                    }
                }

                compactBottomPanel(layout: layout)
                    .position(
                        x: 196.5,
                        y: layout.canvasHeight - compactBottomPanelHeight(layout: layout) / 2
                    )
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .confirmationDialog("Add a photo", isPresented: $showsSourceDialog, titleVisibility: .visible) {
            Button("Photo Library") {
                showsPhotoLibrary = true
            }
            Button("Camera") {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showsCamera = true
                } else {
                    showsPhotoLibrary = true
                }
            }
            Button("Cancel", role: .cancel) {
                showsSourceDialog = false
            }
        }
        .photosPicker(
            isPresented: $showsPhotoLibrary,
            selection: $selectedPhotoItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fullScreenCover(isPresented: $showsCamera) {
            PhotoCameraPicker(
                onImage: { data in
                    selectedPhotoData = data
                    resetCropTransform()
                    showsCamera = false
                },
                onCancel: {
                    showsCamera = false
                }
            )
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showsPhotoEditor) {
            if let selectedPhotoData {
                PhotoCropEditorView(
                    imageData: selectedPhotoData,
                    onBack: {
                        showsPhotoEditor = false
                    },
                    onSave: { croppedData in
                        self.selectedPhotoData = croppedData
                        resetCropTransform()
                        showsPhotoEditor = false
                    }
                )
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                let data = try? await item?.loadTransferable(type: Data.self)
                await MainActor.run {
                    selectedPhotoData = data
                    resetCropTransform()
                }
            }
        }
    }

    private var creatorTopBar: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 116)

            Button(action: onBack) {
                Image("app_btn_back")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .position(x: 34, y: 86)

            Text(creationMode == .video ? "AI Video Creator" : "AI Photo Creator")
                .font(AITheme.Typography.sfProDisplay(20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 220, alignment: .leading)
                .position(x: 168, y: 86)
        }
        .frame(width: 393, height: 116)
    }

    private var uploadPhotoButton: some View {
        Button {
            showsSourceDialog = true
        } label: {
            ZStack {
                Image("app_bg_add")
                    .resizable()
                    .frame(width: 356, height: 166)

                VStack(spacing: 8) {
                    Image("app_ic_add")
                        .resizable()
                        .frame(width: 36, height: 36)
                    Text("Click to upload photo")
                        .font(AITheme.Typography.sfProDisplay(10, weight: .regular))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 356, height: 166)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Upload photo")
    }

    private func compactCreatorContent(layout: DesignCanvasLayout) -> some View {
        let panelHeight = compactBottomPanelHeight(layout: layout)
        let contentTop: CGFloat = 116
        let contentBottom = layout.canvasHeight - panelHeight

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                if let selectedImage {
                    selectedPhotoPreview(selectedImage, side: 260)
                } else {
                    uploadPhotoButton
                }

                compactTemplateSection
                    .padding(.top, 16)
            }
            .frame(width: 393)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .frame(width: 393, height: max(180, contentBottom - contentTop))
        .position(x: 196.5, y: (contentTop + contentBottom) / 2)
    }

    private var compactTemplateSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Select a template")
                    .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button(action: onSeeAll) {
                    Text("See all")
                        .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                        .foregroundStyle(Color(red: 0.647, green: 0.647, blue: 0.647))
                        .frame(width: 64, height: 32, alignment: .trailing)
                }
                .buttonStyle(.plain)
                .frame(width: 64, height: 32)
                .contentShape(Rectangle())
            }
            .frame(width: 356, height: 32)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(templates) { template in
                            Button {
                                selectedTemplate = template
                            } label: {
                                PhotoCreatorTemplateCard(
                                    template: template,
                                    isSelected: selectedTemplate == template
                                )
                            }
                            .buttonStyle(.plain)
                            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .id(template.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
                .onAppear {
                    proxy.scrollTo(selectedTemplate.id, anchor: .center)
                }
                .onChange(of: selectedTemplate) { _, template in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(template.id, anchor: .center)
                    }
                }
            }
            .frame(width: 393, height: 170)
        }
    }

    private func selectedPhotoPreview(_ image: UIImage, side: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Color.black

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: side, height: side)

            cropControls
            .padding(.bottom, 18)
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func transformedPhoto(_ image: UIImage) -> some View {
        let photo = Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: cropViewportSide, height: cropViewportSide)
            .scaleEffect(cropScale)
            .rotationEffect(cropRotation)
            .offset(cropOffset)

        if isCropping {
            photo
                .gesture(cropDragGesture)
                .simultaneousGesture(cropMagnificationGesture)
                .simultaneousGesture(cropRotationGesture)
        } else {
            photo
        }
    }

    private var cropControls: some View {
        HStack(spacing: 8) {
            circularEditorButton(systemName: "crop", accessibilityLabel: "Crop photo") {
                showsPhotoEditor = true
            }

            circularEditorButton(
                systemName: "arrow.triangle.2.circlepath",
                accessibilityLabel: "Change photo"
            ) {
                showsSourceDialog = true
            }
        }
    }

    private func circularEditorButton(
        systemName: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.42), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }

    private var cropDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard let selectedImage else { return }
                let proposedOffset = CGSize(
                    width: committedCropOffset.width + value.translation.width,
                    height: committedCropOffset.height + value.translation.height
                )
                cropOffset = clampedCropOffset(
                    proposedOffset,
                    image: selectedImage,
                    scale: cropScale,
                    rotation: cropRotation
                )
            }
            .onEnded { _ in
                guard let selectedImage else { return }
                cropOffset = clampedCropOffset(
                    cropOffset,
                    image: selectedImage,
                    scale: cropScale,
                    rotation: cropRotation
                )
                committedCropOffset = cropOffset
            }
    }

    private var cropMagnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                guard let selectedImage else { return }
                let minimumScale = minimumCropScale(for: selectedImage, rotation: cropRotation)
                cropScale = min(max(committedCropScale * value, minimumScale), 6)
                cropOffset = clampedCropOffset(
                    cropOffset,
                    image: selectedImage,
                    scale: cropScale,
                    rotation: cropRotation
                )
            }
            .onEnded { _ in
                committedCropScale = cropScale
                committedCropOffset = cropOffset
            }
    }

    private var cropRotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                guard let selectedImage else { return }
                let newRotation = committedCropRotation + value
                cropRotation = newRotation
                cropScale = max(cropScale, minimumCropScale(for: selectedImage, rotation: newRotation))
                cropOffset = clampedCropOffset(
                    cropOffset,
                    image: selectedImage,
                    scale: cropScale,
                    rotation: newRotation
                )
            }
            .onEnded { _ in
                committedCropRotation = cropRotation
                committedCropScale = cropScale
                committedCropOffset = cropOffset
            }
    }

    private func templateSection(
        layout: DesignCanvasLayout,
        titleY: CGFloat,
        listY: CGFloat
    ) -> some View {
        ZStack(alignment: .topLeading) {
            Text("Select a template")
                .font(AITheme.Typography.sfProDisplay(16, weight: .semibold))
                .foregroundStyle(.white)
                .position(x: 79.5, y: layout.y(titleY))

            Button(action: onSeeAll) {
                Text("See all")
                    .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.647, green: 0.647, blue: 0.647))
                    .frame(width: 64, height: 44, alignment: .trailing)
            }
            .buttonStyle(.plain)
            .position(x: 342, y: layout.y(titleY - 0.5))

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(templates) { template in
                            Button {
                                selectedTemplate = template
                            } label: {
                                PhotoCreatorTemplateCard(
                                    template: template,
                                    isSelected: selectedTemplate == template
                                )
                            }
                            .buttonStyle(.plain)
                            .id(template.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                }
                .onAppear {
                    proxy.scrollTo(selectedTemplate.id, anchor: .center)
                }
                .onChange(of: selectedTemplate) { _, template in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(template.id, anchor: .center)
                    }
                }
            }
            .frame(width: 393, height: 170)
            .position(x: 196.5, y: layout.y(listY))
        }
        .frame(width: 393, height: layout.canvasHeight, alignment: .topLeading)
    }

    private func compactBottomPanel(layout: DesignCanvasLayout) -> some View {
        let isCompactHeight = layout.isCompactHeight
        let panelHeight = compactBottomPanelHeight(layout: layout)

        return ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(Color(red: 0.073, green: 0.078, blue: 0.094))

            if creationMode == .video {
                VideoQualitySelector(selection: $videoQuality)
                    .position(x: 196.5, y: isCompactHeight ? 25 : 32)
            }

            PrimaryGradientButton(
                title: "Create",
                isEnabled: selectedPhotoData != nil,
                action: submitCreation
            )
            .frame(width: 356)
            .position(
                x: 196.5,
                y: isCompactHeight
                    ? (creationMode == .video ? 78 : 44)
                    : (creationMode == .video ? 91 : 46)
            )
        }
        .frame(width: 393, height: panelHeight)
    }

    private func compactBottomPanelHeight(layout: DesignCanvasLayout) -> CGFloat {
        guard layout.isCompactHeight else { return 134 }
        return creationMode == .video ? 112 : 88
    }

    private func commitCrop() {
        if let selectedImage {
            cropScale = max(cropScale, minimumCropScale(for: selectedImage, rotation: cropRotation))
            cropOffset = clampedCropOffset(
                cropOffset,
                image: selectedImage,
                scale: cropScale,
                rotation: cropRotation
            )
        }
        committedCropScale = cropScale
        committedCropOffset = cropOffset
        committedCropRotation = cropRotation
        isCropping = false
    }

    private func prepareCropForEditing() {
        guard let selectedImage else { return }
        cropScale = max(cropScale, minimumCropScale(for: selectedImage, rotation: cropRotation))
        cropOffset = clampedCropOffset(
            cropOffset,
            image: selectedImage,
            scale: cropScale,
            rotation: cropRotation
        )
        committedCropScale = cropScale
        committedCropOffset = cropOffset
        isCropping = true
    }

    private func minimumCropScale(for image: UIImage, rotation: Angle) -> CGFloat {
        let displayedSize = baseDisplayedImageSize(for: image)
        let radians = CGFloat(rotation.radians)
        let coverageSide = cropViewportSide * (abs(cos(radians)) + abs(sin(radians)))
        return min(
            6,
            max(
                1,
                max(coverageSide / displayedSize.width, coverageSide / displayedSize.height)
            )
        )
    }

    private func clampedCropOffset(
        _ proposedOffset: CGSize,
        image: UIImage,
        scale: CGFloat,
        rotation: Angle
    ) -> CGSize {
        let displayedSize = baseDisplayedImageSize(for: image)
        let radians = CGFloat(rotation.radians)
        let cosine = cos(radians)
        let sine = sin(radians)
        let cropHalfExtent = cropViewportSide * 0.5 * (abs(cosine) + abs(sine))
        let maximumLocalX = max(0, displayedSize.width * scale * 0.5 - cropHalfExtent)
        let maximumLocalY = max(0, displayedSize.height * scale * 0.5 - cropHalfExtent)

        var localX = proposedOffset.width * cosine + proposedOffset.height * sine
        var localY = -proposedOffset.width * sine + proposedOffset.height * cosine
        localX = min(max(localX, -maximumLocalX), maximumLocalX)
        localY = min(max(localY, -maximumLocalY), maximumLocalY)

        return CGSize(
            width: localX * cosine - localY * sine,
            height: localX * sine + localY * cosine
        )
    }

    private func baseDisplayedImageSize(for image: UIImage) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else {
            return CGSize(width: cropViewportSide, height: cropViewportSide)
        }
        let fillScale = max(
            cropViewportSide / image.size.width,
            cropViewportSide / image.size.height
        )
        return CGSize(
            width: image.size.width * fillScale,
            height: image.size.height * fillScale
        )
    }

    private func resetCropTransform() {
        isCropping = false
        cropScale = 1
        committedCropScale = 1
        cropOffset = .zero
        committedCropOffset = .zero
        cropRotation = .zero
        committedCropRotation = .zero
    }

    private func submitCreation() {
        guard let sourceImageData = selectedPhotoData else { return }

        let request = PhotoCreationRequest(
            sourceImageData: sourceImageData,
            styleReferenceImageData: UIImage(named: selectedTemplate.asset)?.pngData(),
            template: selectedTemplate,
            prompt: selectedTemplate.prompt
        )
        onCreate(request)
    }

    private func renderedCroppedPhotoData() -> Data? {
        guard let image = selectedImage else { return nil }

        let outputSide: CGFloat = 1024
        let previewSide: CGFloat = 345
        let outputSize = CGSize(width: outputSide, height: outputSide)
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: outputSize))

            let baseScale = max(
                outputSide / max(image.size.width, 1),
                outputSide / max(image.size.height, 1)
            )
            let effectiveScale = baseScale * cropScale
            let drawSize = CGSize(
                width: image.size.width * effectiveScale,
                height: image.size.height * effectiveScale
            )
            let offsetMultiplier = outputSide / previewSide

            cgContext.translateBy(
                x: outputSide / 2 + cropOffset.width * offsetMultiplier,
                y: outputSide / 2 + cropOffset.height * offsetMultiplier
            )
            cgContext.rotate(by: CGFloat(cropRotation.radians))

            image.draw(
                in: CGRect(
                    x: -drawSize.width / 2,
                    y: -drawSize.height / 2,
                    width: drawSize.width,
                    height: drawSize.height
                )
            )
        }

        return renderedImage.jpegData(compressionQuality: 0.94)
    }
}

private enum PhotoCropAspect: String, CaseIterable, Identifiable {
    case original = "Original"
    case portrait = "9:16"
    case portraitClassic = "3:4"
    case square = "1:1"
    case landscapeClassic = "4:3"
    case landscape = "16:9"

    var id: String { rawValue }

    func ratio(for image: UIImage) -> CGFloat {
        switch self {
        case .original:
            guard image.size.height > 0 else { return 1 }
            return image.size.width / image.size.height
        case .portrait: return 9 / 16
        case .portraitClassic: return 3 / 4
        case .square: return 1
        case .landscapeClassic: return 4 / 3
        case .landscape: return 16 / 9
        }
    }
}

private struct PhotoCropEditorView: View {
    let imageData: Data
    let onBack: () -> Void
    let onSave: (Data) -> Void

    @State private var selectedAspect: PhotoCropAspect = .original
    @State private var cropScale: CGFloat = 1
    @State private var committedCropScale: CGFloat = 1
    @State private var cropOffset: CGSize = .zero
    @State private var committedCropOffset: CGSize = .zero

    private let maximumViewportSize = CGSize(width: 345, height: 516)

    private var image: UIImage? {
        UIImage(data: imageData)
    }

    var body: some View {
        DesignCanvas { layout in
            ZStack(alignment: .topLeading) {
                AITheme.ColorToken.background.ignoresSafeArea()
                editorTopBar

                if let image {
                    cropViewport(image)
                        .scaleEffect(layout.isCompactHeight ? 0.68 : 1)
                        .position(x: 196.5, y: layout.y(390))
                }

                bottomPanel
                    .position(x: 196.5, y: layout.canvasHeight - 100)
            }
            .frame(width: 393, height: layout.canvasHeight)
            .statusBarHidden(false)
        }
        .ignoresSafeArea()
        .onChange(of: selectedAspect) { _, _ in
            resetTransform()
        }
    }

    private var editorTopBar: some View {
        ZStack(alignment: .topLeading) {
            AITheme.ColorToken.background
                .frame(width: 393, height: 116)

            Button(action: onBack) {
                Image("app_btn_back")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            .position(x: 34, y: 86)

            Text("Photo Editor")
                .font(AITheme.Typography.sfProDisplay(20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 220, alignment: .leading)
                .position(x: 168, y: 86)
        }
        .frame(width: 393, height: 116)
    }

    private func cropViewport(_ image: UIImage) -> some View {
        let viewportSize = viewportSize(for: image)

        return ZStack {
            Color.black

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: viewportSize.width, height: viewportSize.height)
                .scaleEffect(cropScale)
                .offset(cropOffset)
        }
        .frame(width: viewportSize.width, height: viewportSize.height)
        .clipped()
        .overlay {
            Rectangle()
                .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)
        }
        .contentShape(Rectangle())
        .gesture(cropDragGesture(image: image, viewportSize: viewportSize))
        .simultaneousGesture(cropMagnificationGesture(image: image, viewportSize: viewportSize))
    }

    private var bottomPanel: some View {
        ZStack {
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(Color(red: 0.073, green: 0.078, blue: 0.094))

            VStack(spacing: 24) {
                HStack(spacing: 9) {
                    ForEach(PhotoCropAspect.allCases) { aspect in
                        Button {
                            selectedAspect = aspect
                        } label: {
                            PhotoCropAspectOption(
                                aspect: aspect,
                                isSelected: selectedAspect == aspect
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 356)

                PrimaryGradientButton(title: "Save", showsBorder: false) {
                    guard let image,
                          let croppedData = renderedCropData(image: image) else { return }
                    onSave(croppedData)
                }
                .frame(width: 356)
            }
            .padding(.top, 18)
        }
        .frame(width: 393, height: 200)
    }

    private func viewportSize(for image: UIImage) -> CGSize {
        let ratio = max(selectedAspect.ratio(for: image), 0.01)
        let maximumRatio = maximumViewportSize.width / maximumViewportSize.height

        if ratio >= maximumRatio {
            return CGSize(
                width: maximumViewportSize.width,
                height: maximumViewportSize.width / ratio
            )
        }

        return CGSize(
            width: maximumViewportSize.height * ratio,
            height: maximumViewportSize.height
        )
    }

    private func cropDragGesture(image: UIImage, viewportSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let proposedOffset = CGSize(
                    width: committedCropOffset.width + value.translation.width,
                    height: committedCropOffset.height + value.translation.height
                )
                cropOffset = clampedOffset(
                    proposedOffset,
                    image: image,
                    viewportSize: viewportSize,
                    scale: cropScale
                )
            }
            .onEnded { _ in
                cropOffset = clampedOffset(
                    cropOffset,
                    image: image,
                    viewportSize: viewportSize,
                    scale: cropScale
                )
                committedCropOffset = cropOffset
            }
    }

    private func cropMagnificationGesture(image: UIImage, viewportSize: CGSize) -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                cropScale = min(max(committedCropScale * value, 1), 6)
                cropOffset = clampedOffset(
                    cropOffset,
                    image: image,
                    viewportSize: viewportSize,
                    scale: cropScale
                )
            }
            .onEnded { _ in
                committedCropScale = cropScale
                committedCropOffset = cropOffset
            }
    }

    private func clampedOffset(
        _ proposedOffset: CGSize,
        image: UIImage,
        viewportSize: CGSize,
        scale: CGFloat
    ) -> CGSize {
        let displayedSize = baseDisplayedImageSize(image: image, viewportSize: viewportSize)
        let maximumX = max(0, (displayedSize.width * scale - viewportSize.width) * 0.5)
        let maximumY = max(0, (displayedSize.height * scale - viewportSize.height) * 0.5)

        return CGSize(
            width: min(max(proposedOffset.width, -maximumX), maximumX),
            height: min(max(proposedOffset.height, -maximumY), maximumY)
        )
    }

    private func baseDisplayedImageSize(image: UIImage, viewportSize: CGSize) -> CGSize {
        guard image.size.width > 0, image.size.height > 0 else { return viewportSize }
        let fillScale = max(
            viewportSize.width / image.size.width,
            viewportSize.height / image.size.height
        )
        return CGSize(
            width: image.size.width * fillScale,
            height: image.size.height * fillScale
        )
    }

    private func renderedCropData(image: UIImage) -> Data? {
        let ratio = max(selectedAspect.ratio(for: image), 0.01)
        let outputSize: CGSize

        if ratio >= 1 {
            outputSize = CGSize(width: 1024, height: (1024 / ratio).rounded())
        } else {
            outputSize = CGSize(width: (1024 * ratio).rounded(), height: 1024)
        }

        let viewportSize = viewportSize(for: image)
        let outputMultiplier = outputSize.width / viewportSize.width
        let rendererFormat = UIGraphicsImageRendererFormat()
        rendererFormat.scale = 1
        rendererFormat.opaque = true
        let renderer = UIGraphicsImageRenderer(size: outputSize, format: rendererFormat)
        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: outputSize))

            let baseScale = max(
                outputSize.width / max(image.size.width, 1),
                outputSize.height / max(image.size.height, 1)
            )
            let effectiveScale = baseScale * cropScale
            let drawSize = CGSize(
                width: image.size.width * effectiveScale,
                height: image.size.height * effectiveScale
            )

            cgContext.translateBy(
                x: outputSize.width * 0.5 + cropOffset.width * outputMultiplier,
                y: outputSize.height * 0.5 + cropOffset.height * outputMultiplier
            )
            image.draw(
                in: CGRect(
                    x: -drawSize.width * 0.5,
                    y: -drawSize.height * 0.5,
                    width: drawSize.width,
                    height: drawSize.height
                )
            )
        }

        return renderedImage.jpegData(compressionQuality: 0.94)
    }

    private func resetTransform() {
        cropScale = 1
        committedCropScale = 1
        cropOffset = .zero
        committedCropOffset = .zero
    }
}

private struct PhotoCropAspectOption: View {
    let aspect: PhotoCropAspect
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            aspectIcon
                .frame(width: 42, height: 30)

            Text(aspect.rawValue)
                .font(AITheme.Typography.sfProDisplay(11, weight: .regular))
                .foregroundStyle(isSelected ? .white : Color.white.opacity(0.36))
                .lineLimit(1)
        }
        .frame(width: 51, height: 54)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var aspectIcon: some View {
        if aspect == .original {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.36), lineWidth: 1)
                    .frame(width: 25, height: 25)
                    .offset(x: 4, y: 2)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.36), lineWidth: 1)
                    .frame(width: 25, height: 25)
                    .offset(x: -4, y: -2)
            }
        } else {
            let ratio = aspect.ratio(for: UIImage())
            let size = iconSize(for: ratio)
            RoundedRectangle(cornerRadius: 3)
                .stroke(isSelected ? Color.white : Color.white.opacity(0.36), lineWidth: 1)
                .frame(width: size.width, height: size.height)
        }
    }

    private func iconSize(for ratio: CGFloat) -> CGSize {
        if ratio >= 1 {
            return CGSize(width: 32, height: max(10, 32 / ratio))
        }
        return CGSize(width: max(10, 26 * ratio), height: 26)
    }
}

private struct CropGridOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.9), lineWidth: 1)

                Path { path in
                    let width = proxy.size.width
                    let height = proxy.size.height
                    let inset: CGFloat = 1

                    for fraction in [CGFloat(1) / 3, CGFloat(2) / 3] {
                        let x = width * fraction
                        path.move(to: CGPoint(x: x, y: inset))
                        path.addLine(to: CGPoint(x: x, y: height - inset))

                        let y = height * fraction
                        path.move(to: CGPoint(x: inset, y: y))
                        path.addLine(to: CGPoint(x: width - inset, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.82), lineWidth: 1)
            }
            .padding(1)
        }
    }
}

private struct PhotoCreatorTemplateCard: View {
    let template: PhotoTemplateStyle
    let isSelected: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(template.asset)
                .resizable()
                .scaledToFill()
                .frame(width: 116, height: 166)

            if !template.isPrecomposed {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0.62),
                        .init(color: .black.opacity(0.5), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(template.title)
                    .font(AITheme.Typography.sfProDisplay(12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                    .padding(.trailing, 6)
                    .padding(.top, 144)
            }

            if templateBadge == .trend {
                Image("app_ic_trend")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(.top, 8)
                    .padding(.trailing, 8)
            }
        }
        .frame(width: 116, height: 166)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white, lineWidth: 2)
            }
        }
    }

    private var templateBadge: PhotoTemplateBadge {
        let categoryTemplates = PhotoTemplateStyle.templates(for: template.category)
        let index = categoryTemplates.firstIndex(where: { $0.asset == template.asset }) ?? 0
        return PhotoTemplateStyle.badge(for: template, at: index, in: template.category)
    }
}

struct PhotoCameraPicker: UIViewControllerRepresentable {
    let onImage: (Data) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        private let onImage: (Data) -> Void
        private let onCancel: () -> Void

        init(onImage: @escaping (Data) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.92) {
                onImage(data)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
