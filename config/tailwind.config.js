module.exports = {
  content: [
    "./public/*.html",
    "app/assets/stylesheets/application.tailwind.css",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      fontFamily: {
        serif: ["Lora Variable", 'ui-serif', 'Georgia', 'Cambria', "Times New Roman", 'Times', 'serif'],
        sans: ["Inter Variable", 'ui-sans-serif', 'system-ui', 'sans-serif', "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"],
      },
      boxShadow: {
        "with-inset":
          "0 0 0 1px #70451a1a,0 1px 2px #70451a0a,0 3px 5px #70451a33,0 -5px #f0f0efcc inset",
        "without-inset":
          "0 0 0 1px #70451a1a,0 1px 2px #70451a0a,0 3px 5px #70451a33",
      },
      colors: {
        newsletter: {
          primary: "var(--color-newsletter-primary)",
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
