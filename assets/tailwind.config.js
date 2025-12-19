const colors = require("tailwindcss/colors");

module.exports = {
  content: ["../lib/*_web/**/*.*ex", "./js/**/*.js"],
  theme: {
    extend: {
      fontFamily: {
        sans: ['"Nunito Sans"', 'sans-serif'],
      },
      colors: {
        primary: {
          50: '#FFF9E9',   // --color--ly1
          100: '#FFF3D3',  // --color--ly2
          200: '#FFEDBC',  // --color--ly3
          300: '#FFDE9E',
          400: '#FFD06B',
          500: '#FFC421',  // --color--brand-yellow (primary)
          600: '#FFA100',  // --color--y4
          700: '#FF8D03',  // --color--y5
          800: '#E67A00',
          900: '#CC6C00',
        },
        secondary: {
          50: '#E9EEFF',   // --color--lb1
          100: '#D3DDFF',  // --color--lb2
          200: '#BCCCFF',  // --color--lb3
          300: '#8BA8FF',
          400: '#5A84FF',
          500: '#2153FF',  // --color--accent-blue
          600: '#216FFF',  // --color--b1
          700: '#2185FF',  // --color--b2
          800: '#2197FF',  // --color--b3
          900: '#1A3ACC',
        },
        'dark-blue': {
          DEFAULT: '#000824',  // --color--dark-blue
          light: '#0D142F',    // --color--db1
          medium: '#1A213A',   // --color--db2
          muted: '#262D45',    // --color--db3
        },
        danger: colors.red,
      },
    },
  },

  safelist: [
    "col-start-1",
    "col-start-2",
    "col-start-3",
    "col-start-4",
    "col-start-5",
    "col-start-6",
    "col-start-7",
    "col-start-8",
    "col-start-9",

    "h-screen",

    "bg-gray-300",
    "bg-red-300",
    "bg-yellow-300",
    "bg-green-300",
    "bg-blue-300",
    "bg-indigo-300",
    "bg-pink-300",
    "bg-purple-300",

    "bg-gray-400",
    "bg-red-400",
    "bg-yellow-400",
    "bg-green-400",
    "bg-blue-400",
    "bg-indigo-400",
    "bg-pink-400",
    "bg-purple-400",

    "bg-gray-100",
    "bg-red-100",
    "bg-yellow-100",
    "bg-green-100",
    "bg-blue-100",
    "bg-indigo-100",
    "bg-pink-100",
    "bg-purple-100",

    "text-gray-800",
    "text-red-800",
    "text-yellow-800",
    "text-green-800",
    "text-blue-800",
    "text-indigo-800",
    "text-pink-800",
    "text-purple-800",

    "border-l-gray-500",
    "border-l-red-500",
    "border-l-yellow-500",
    "border-l-green-500",
    "border-l-blue-500",
    "border-l-indigo-500",
    "border-l-pink-500",
    "border-l-purple-500",

    "text-gray-300",
    "text-red-300",
    "text-yellow-300",
    "text-green-300",
    "text-blue-300",
    "text-indigo-300",
    "text-pink-300",
    "text-purple-300",
  ],
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    require("@tailwindcss/line-clamp"),
    require("@tailwindcss/aspect-ratio"),
  ],
  darkMode: "class",
};
