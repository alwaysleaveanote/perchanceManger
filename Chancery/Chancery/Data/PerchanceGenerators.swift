import Foundation

/// A Perchance generator option with metadata
struct PerchanceGeneratorOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let name: String
}

/// Shared list of available Perchance generators (sorted alphabetically by name)
let perchanceGenerators: [PerchanceGeneratorOption] = [
    PerchanceGeneratorOption(
        title: "🖼 AI Image Generator (free, no sign-up, unlimited, uncensored)",
        description: "A *fast*, unlimited, no login (ever!!!), AI image generator. Generate large *batches* of images all in just a few seconds. Generate AI art from text, completely free, online, no login or sign-up, no daily credit limits/restrictions/gimmicks, and it's fast. Other AI art generators often have annoying daily credit limits and require sign-up, or are slow - this one doesn't. Use this AI to generate high quality art, photos, cartoons, drawings, anime, thumbnails, pfps, and more. Create OCs, anime characters, AI villains, fanfic artwork, and pretty much anything else. It's an AI-based image generator - i.e. a text-to-image model. No watermark, no account needed, unlimited images. Type words, make pics.",
        name: "ai-images-generator"
    ),
    PerchanceGeneratorOption(
        title: "",
        description: "a furry image generator",
        name: "furry-ai"
    ),
    PerchanceGeneratorOption(
        title: "",
        description: "a new version of furry-ai",
        name: "new-furry-ai"
    ),
    PerchanceGeneratorOption(
        title: "kazuma-ai-generated != 'kazuma-ai-generated' ? '' : \"🎨 Essaadny AI Art Generator 🎭 - The Official Arabic Tool\"",
        description: "kazuma-ai-generated != 'kazuma-ai-generated' ? '' : \"The official Asaadni AI Art Generator for the Arabic language - smart prompts, fast tools, gallery, comments, and diverse artistic styles.\"",
        name: "kazuma-ai-generated"
    ),
    PerchanceGeneratorOption(
        title: "Vibrant",
        description: "Generate anime images with random options, 150 styles, outfits, scenery, anime characters, advanced tools, simple, customizable, advanced.",
        name: "ai-vibrant-image-generator"
    ),
    PerchanceGeneratorOption(
        title: "Unsafe Images",
        description: "Create stunning and imaginative AI images instantly. No filters, no restrictions – just endless creativity with this powerful free AI image generator, chat, image to image, image to video, story, character creator.",
        name: "unsafeimagesgenerator"
    ),
    PerchanceGeneratorOption(
        title: "Hot or Not Generators",
        description: "🖥️ Pop-up Previews | 🏆 Top 550 Gens | 🔥 Rank Your Likes | 💌 Pin Your Favs |",
        name: "hot-or-not-generators"
    ),
    PerchanceGeneratorOption(
        title: "Phenomenally Popular Generators",
        description: "Just the normal generators page, but filtered to 5000+ views!",
        name: "phenomenally-popular-generators"
    ),
    PerchanceGeneratorOption(
        title: "The Imaginarium",
        description: "A glitch in the dream grid. Neon code dripping with aesthetic nostalgia. This Perchance generator hums in pink static and vapor light—where data meets desire and art becomes algorithm.",
        name: "the-imaginarium"
    ),
    PerchanceGeneratorOption(
        title: "Image Brewery",
        description: "Easy image creation! Make your own styles! Or total chaos! Art is also a possibility. (fill out all fields, for best results)",
        name: "image-style-creator"
    ),
    PerchanceGeneratorOption(
        title: "Perchance AI Furry Generator",
        description: "Generate free furry AI art & fursona, unlimited, no sign-up. Join the Perchance community for AI character roleplay and prompts, powered by FLUX.",
        name: "ai-furry-generator"
    ),
    PerchanceGeneratorOption(
        title: "✧✨🌿 Beautiful People 🌿✨✧ free Text2Image AI ART",
        description: "Generate absolutely beautiful people. Flux AI Image. free ai art. forever unlimited. no signup. no watermark",
        name: "beautiful-people"
    ),
    PerchanceGeneratorOption(
        title: "Fine grain",
        description: "image enhance, flux, free, take any image and enhance it and upscale it highly detailed images that are perfect for use with the new perchance model.",
        name: "finegrain"
    ),
    PerchanceGeneratorOption(
        title: "AI Image Prompt Generator",
        description: "",
        name: "glassprompt"
    ),
    PerchanceGeneratorOption(
        title: "Fancy-Feast",
        description: "image to prompt, flux, free, take any image and generate highly detailed specific prompts that are perfect for use with the new perchance model.",
        name: "fancy-feast"
    ),
    PerchanceGeneratorOption(
        title: "try-this",
        description: "A curated list of helpful tools and resources for AI image generation, prompt crafting, and creative inspiration. Discover the best AI art generators, prompt builders, and tools to enhance your AI art creation process.",
        name: "try-this"
    ),
    PerchanceGeneratorOption(
        title: "The Best Image Generator",
        description: "The best perchance image generator.",
        name: "best-ai-image-generator"
    ),
    PerchanceGeneratorOption(
        title: "The Page 217",
        description: "The profile of The Page 217.",
        name: "the-page-217"
    ),
    PerchanceGeneratorOption(
        title: "The Ginger Generator",
        description: "A generator of redheads and freckles.",
        name: "ginger-generator"
    ),
    PerchanceGeneratorOption(
        title: "An Image Generator",
        description: "One of the best perchance image generators.",
        name: "an-image-generator"
    ),
    PerchanceGeneratorOption(
        title: "Genshin Impact Boss + Character Generator (updated 6.2",
        description: "option to choose between all, weekly, or world bosses + nod krai section added",
        name: "genshin-impact-boss-and-character-generator"
    ),
    PerchanceGeneratorOption(
        title: "Free No Limit AI Image Generator (Text to Image PREMIUM EDITION)",
        description: "Imagine unlocking a world of limitless creativity with our AI Image Generator! No sign-ups, no hassles, just pure imagination brought to life. Simply type 'imagine' followed by your description, and watch as our AI crafts flawless, one-of-a-kind images that exceed your wildest dreams. From surreal landscapes to hyper-realistic portraits, the possibilities are endless. Try it now and discover the magic of AI-powered art!",
        name: "q5i0xbm31n"
    ),
    PerchanceGeneratorOption(
        title: "Qinegen Image Generator (no-limit, no sign-up)",
        description: "Qinegen - Multifaceted AI text to image generator. Extended features - image-to-text, Character Chat, Ai Helper, Gallery changer, many styles, and etc. Chats and image gallery. Free, No sign up, No login, No limits, No watermark, limitless. Anime, Realistic, 3D, Cartoon, and more",
        name: "qinegen"
    ),
    PerchanceGeneratorOption(
        title: "Tony Pro's Cold War Generator",
        description: "",
        name: "cold-war-1970s-generator"
    ),
    PerchanceGeneratorOption(
        title: "URVILLAIN Imagine – Advanced AI Art & Image Generator",
        description: "Free, Unlimited & No Sign-Up AI Flux Schnell Image Generator: Realistic, Anime, & More.",
        name: "urvillain-imagine"
    ),
    PerchanceGeneratorOption(
        title: "AetherPortrait: Create Stunning, Realistic AI Portraits Instantly - Free, No Signup",
        description: "Transform ideas into breathtaking AI portraits in seconds. AetherPortrait offers unlimited free generations, private gallery, AI prompt assistant & realistic people creation. No login required.",
        name: "realistic-people"
    ),
    PerchanceGeneratorOption(
        title: "Furchance",
        description: "☢️ Furchance Nuclear Power Generator",
        name: "furchance"
    ),
    PerchanceGeneratorOption(
        title: "Create a Random Generator",
        description: "",
        name: "4bdntoolhubnsfw"
    ),
    PerchanceGeneratorOption(
        title: "text2image-generator",
        description: "An AI image generator with extended controls, 100+ styles, chats, and an image gallery.",
        name: "text2image-generator"
    ),
    PerchanceGeneratorOption(
        title: "Perchance generators",
        description: "NEW Perchance generators list .",
        name: "pergens"
    ),
    PerchanceGeneratorOption(
        title: "AI ARTGEN — A fast, free, unlimited AI image generator",
        description: "A fast, free, unlimited AI art generator with a wide variety of art styles to mix and match.",
        name: "ai-artgen"
    ),
    PerchanceGeneratorOption(
        title: "My Amazing AI Character Generator",
        description: "Create unique and surprising characters with the help of artificial intelligence! Ideal for RPGs, stories, games, or just for fun. Completely free, no registration needed, and unlimited use.",
        name: "u0fiqodll1"
    ),
    PerchanceGeneratorOption(
        title: "Prompty",
        description: "Smart AI prompt generator",
        name: "promptyx"
    ),
    PerchanceGeneratorOption(
        title: "NEXBOX — Free ai image generator",
        description: "Free image generator, Easy, fast, with more options and styles.",
        name: "nexbox"
    ),
    PerchanceGeneratorOption(
        title: "AI Character Chat (online, free, no sign-up, unlimited)",
        description: "Fork of the original Perchance AI Chat - completely free, online, no login, unlimited messages, unlimited AI-generated images. Chat with AI characters via this Character.AI (C.AI) chat alternative. Custom AI character creation. Chat to the default Chloe character, or make your own AI character and talk to them freely - no limits, and no freemium gimicks that lure you to sign up. No message limits, no filter. You can create characters that can send pictures/images/photos, roleplay chatbots, AI RPGs/D&D experiences, an AI Dungeon alternative, anime AI chat, and basically anything else you can think of. No restrictions on daily usage. Like ChatGPT, but for fictional character RPs and AI characters, with image generation in chat.",
        name: "new-ai-chat-gen"
    )
].sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
