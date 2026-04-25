---
name: Precision Asset Logic
colors:
  surface: '#f7f9fb'
  surface-dim: '#d8dadc'
  surface-bright: '#f7f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f4f6'
  surface-container: '#eceef0'
  surface-container-high: '#e6e8ea'
  surface-container-highest: '#e0e3e5'
  on-surface: '#191c1e'
  on-surface-variant: '#434653'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eff1f3'
  outline: '#737784'
  outline-variant: '#c3c6d5'
  surface-tint: '#1d59c1'
  primary: '#003c90'
  on-primary: '#ffffff'
  primary-container: '#0f52ba'
  on-primary-container: '#bcceff'
  inverse-primary: '#b0c6ff'
  secondary: '#545f73'
  on-secondary: '#ffffff'
  secondary-container: '#d5e0f8'
  on-secondary-container: '#586377'
  tertiary: '#004565'
  on-tertiary: '#ffffff'
  tertiary-container: '#005e87'
  on-tertiary-container: '#9dd5ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d9e2ff'
  primary-fixed-dim: '#b0c6ff'
  on-primary-fixed: '#001945'
  on-primary-fixed-variant: '#00419c'
  secondary-fixed: '#d8e3fb'
  secondary-fixed-dim: '#bcc7de'
  on-secondary-fixed: '#111c2d'
  on-secondary-fixed-variant: '#3c475a'
  tertiary-fixed: '#c9e6ff'
  tertiary-fixed-dim: '#89ceff'
  on-tertiary-fixed: '#001e2f'
  on-tertiary-fixed-variant: '#004c6e'
  background: '#f7f9fb'
  on-background: '#191c1e'
  surface-variant: '#e0e3e5'
typography:
  h1:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.02em
  h2:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  h3:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  code:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  sidebar-width: 260px
  grid-columns: '12'
  grid-gutter: 20px
---

## Brand & Style

The design system is engineered for the high-stakes environment of enterprise IT asset management. The brand personality is rooted in **Reliability, Precision, and Control**. It aims to evoke a sense of calm efficiency in IT administrators who manage complex inventories and lifecycles.

The chosen style is **Corporate / Modern**. It leverages a structured hierarchy that prioritizes data density without sacrificing readability. The aesthetic is professional and utilitarian, utilizing subtle depth and a restricted color palette to ensure the user's focus remains on hardware metrics and procurement workflows.

## Colors

The color strategy centers on a **Sapphire Blue** primary tone, chosen for its association with trust and institutional stability. 

- **Primary:** Used for primary actions, active states, and brand-critical touchpoints.
- **Secondary (Dark Navy):** Applied to the persistent sidebar to provide a strong visual anchor and high contrast against the main content.
- **Surface:** The main content area utilizes a pure white background to maximize the legibility of data tables and reports.
- **Accents:** A lighter Sky Blue is used for informational badges and subtle highlights to prevent the interface from feeling overly heavy.

## Typography

The design system utilizes **Inter** exclusively to take advantage of its exceptional legibility at small sizes, which is critical for dense asset lists. 

- **Headlines:** Use semi-bold weights with slight negative letter-spacing to maintain a compact, modern feel.
- **Body:** The standard size is set to 14px to allow for high data density while maintaining accessibility.
- **Labels:** Small, all-caps treatments are reserved for table headers and section grouping labels to provide clear structural hierarchy.

## Layout & Spacing

This design system employs a **Fluid Grid** model within a fixed layout shell. The sidebar is fixed at 260px, while the main content area expands to fill the viewport, utilizing a 12-column grid system.

The spacing rhythm is based on a **4px baseline**, ensuring all components align predictably. Padding within cards and modals should scale between 16px and 24px to maintain a professional, airy feel despite the dense information architecture.

## Elevation & Depth

Visual hierarchy is achieved through a combination of **Tonal Layering** and **Ambient Shadows**. 

1. **Base Layer:** Pure white content area.
2. **Component Layer:** Cards and containers use a subtle #E2E8F0 border (1px) and a very soft, diffused shadow (0px 4px 6px -1px rgba(0,0,0,0.1)) to lift them off the background.
3. **Floating Layer:** Modals and dropdowns utilize a more pronounced shadow to indicate higher z-index priority.

The goal is a "layered paper" effect that feels tactile yet digital and clean.

## Shapes

The design system adopts a **Soft** shape language. Standard UI elements like buttons, input fields, and cards use a 0.25rem (4px) corner radius. This small radius maintains a professional, disciplined appearance while avoiding the harshness of sharp corners. Larger containers like modals may use up to 8px (rounded-lg) to soften the overall interface.

## Components

- **Buttons:** Primary buttons use a solid Sapphire Blue fill with white text. Secondary buttons use a transparent background with a 1px Sapphire Blue border.
- **Sidebar Nav:** Navigation items use a subtle hover state (#1E293B) and a primary blue vertical indicator bar on the left for active states.
- **Asset Cards:** Use a 1px border and the "Ambient Shadow" defined in Elevation. Headers within cards should have a subtle bottom border.
- **Status Chips:** Small, rounded-pill indicators for asset health (e.g., "Active," "Retired," "In Repair"). Use low-saturation background tints with high-saturation text.
- **Data Tables:** High-density rows with alternating light gray backgrounds (#F8FAFC) on hover. Borders should be horizontal-only to emphasize the row-based nature of asset lists.
- **Input Fields:** Use a subtle inset shadow and a 1px border. Focus states must be clearly defined with a 2px Sapphire Blue ring.
- **Inventory Metrics:** Large-format numerical displays used at the top of dashboards to provide instant situational awareness.