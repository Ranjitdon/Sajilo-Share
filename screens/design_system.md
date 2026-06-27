---
name: FlatShare Design System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#464554'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#767586'
  outline-variant: '#c7c4d7'
  surface-tint: '#494bd6'
  primary: '#4648d4'
  on-primary: '#ffffff'
  primary-container: '#6063ee'
  on-primary-container: '#fffbff'
  inverse-primary: '#c0c1ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#825100'
  on-tertiary: '#ffffff'
  tertiary-container: '#a36700'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e1e0ff'
  primary-fixed-dim: '#c0c1ff'
  on-primary-fixed: '#07006c'
  on-primary-fixed-variant: '#2f2ebe'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style
The design system is built on a foundation of **Modern Minimalism** infused with **Material 3** principles. It targets roommates who need a frictionless, organized way to manage shared finances without the stress of traditional banking interfaces. 

The aesthetic is professional yet friendly, leaning into a "Fintech-Plus" vibe: high-utility layouts softened by generous white space and rounded geometry. The goal is to evoke a sense of **collective trust and clarity**. Interaction patterns should feel fluid and intentional, reducing the cognitive load of expense tracking through a clean, systematic visual language.

## Colors
The color palette is centered around a vibrant Indigo primary, providing a modern tech-forward anchor. 

- **Primary (#6366F1):** Used for key actions, active states, and branding elements.
- **Secondary (#10B981):** Representing "Credit" or "Settled" states; a positive green to balance the indigo.
- **Tertiary (#F59E0B):** Used for "Pending" or "Warning" states, such as overdue payments.
- **Neutral:** A range of slates (`#F8FAFC` to `#0F172A`) ensures depth and legibility.

In **Light Mode**, surfaces use pure white with subtle slate borders. In **Dark Mode**, the background shifts to a deep Slate-900 to maintain contrast while reducing eye strain during night-time budgeting.

## Typography
This design system utilizes **Inter** across all levels to maintain a systematic and utilitarian feel. The hierarchy is strictly enforced to ensure financial data is digestible at a glance.

- **Display & Headlines:** Used for account balances and screen titles. Bold weights and tight letter spacing create a confident, "locked-in" look.
- **Body:** Optimized for readability. Use `body-lg` for transaction descriptions and `body-sm` for metadata like dates or sub-categories.
- **Labels:** Small, all-caps styling for secondary information like "Owed by you" or "Category tags."

## Layout & Spacing
The layout follows a **Fluid Grid** model based on an 8px square rhythm. 

- **Mobile:** 4-column grid with 20px side margins and 16px gutters.
- **Tablet/Desktop:** 12-column grid with a max-width of 1200px.
- **Spacing Philosophy:** Use `16px (md)` for internal card padding and `24px (lg)` for vertical separation between logical sections. Negative space should be used aggressively to prevent the financial data from feeling "cluttered."

## Elevation & Depth
This design system employs **Tonal Layering** combined with **Ambient Shadows** to create a Material 3-inspired hierarchy.

- **Level 0 (Background):** Flat surface color.
- **Level 1 (Cards/Lists):** Surface color with a subtle 1px border (`neutral-100`) and a very soft, diffused shadow (Offset: 0,4; Blur: 12; Opacity: 0.05).
- **Level 2 (Active/Floating):** Higher elevation for Floating Action Buttons (FAB) or active Modals, using a more pronounced shadow (Offset: 0,8; Blur: 24; Opacity: 0.1) and a slight primary color tint in the shadow for light mode.

## Shapes
The shape language is defined by friendly, approachable curves.

- **Standard Elements (Buttons, Inputs):** 8px (`rounded-md`).
- **Containers (Cards, Bottom Sheets):** 16px (`rounded-lg`) to 24px (`rounded-xl`).
- **Special Elements (Chips, FABs):** Fully rounded/Pill-shaped to distinguish interactive utility elements from content containers.

## Components

- **Buttons:** Primary buttons use a solid Indigo fill with white text. Secondary buttons use a tonal variant (Indigo-50) with Indigo text.
- **Cards:** The core of the UI. Cards must have a minimum of 16px padding and 16px corner radius. Grouped expenses should be displayed in a vertical list within a single card container to maintain "clumped" visual logic.
- **Chips:** Used for expense categories (e.g., "Rent," "Groceries"). Use a small icon followed by a label, with a background color that is a 10% opacity version of the category's assigned color.
- **Input Fields:** Outlined style with a 1px border. On focus, the border thickens to 2px and changes to the Primary color. Labels should use the floating Material 3 pattern.
- **Icons:** Use thick-stroke, rounded-end icons (e.g., Lucide or Phosphor). Each category is assigned a specific icon to allow for rapid visual scanning.
- **Lists:** Transaction items should feature a leading icon (category), a central title/subtitle (description/date), and a trailing value (amount) with color-coding for "Owe" vs "Owed."