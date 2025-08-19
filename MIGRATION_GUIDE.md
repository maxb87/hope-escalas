# Migration Guide: Bootstrap to Tailwind CSS + shadcn/ui

## Overview
This project has been successfully migrated from Bootstrap to Tailwind CSS with shadcn/ui components and TypeScript support.

## Changes Made

### 1. Package Dependencies
- **Removed**: `bootstrap` package
- **Added**: 
  - `tailwindcss` and related packages
  - `@radix-ui/*` components for shadcn/ui
  - `typescript` and type definitions
  - `class-variance-authority`, `clsx`, `tailwind-merge` for component utilities

### 2. Configuration Files
- **Updated**: `tailwind.config.js` with proper content paths and shadcn/ui theme
- **Updated**: `vite.config.mts` with TypeScript support and path aliases
- **Created**: `tsconfig.json` for TypeScript configuration
- **Updated**: `postcss.config.js` (already correct)

### 3. CSS Files
- **Removed**: `application.bootstrap.scss`
- **Created**: `application.tailwind.css` with shadcn/ui CSS variables
- **Updated**: `application.css` to import Tailwind instead of Bootstrap

### 4. JavaScript/TypeScript
- **Updated**: `app/javascript/application.js` (removed Bootstrap import)
- **Created**: `app/javascript/application.tsx` (TypeScript entry point)
- **Created**: `app/javascript/lib/utils.ts` (shadcn/ui utilities)
- **Created**: `app/javascript/components/ui/` directory with shadcn/ui components

### 5. Views
- **Updated**: `app/views/layouts/application.html.erb` with Tailwind classes
- **Updated**: `app/views/devise/sessions/new.html.erb` with modern Tailwind styling
- **Updated**: `app/views/devise/shared/_links.html.erb` with Tailwind classes

### 6. React Components
- **Created**: Example `LoginForm.tsx` component using shadcn/ui
- **Created**: Basic shadcn/ui components (Button, Input, Label, Card)

## Available Commands

```bash
# Build CSS
yarn build:css

# Watch CSS changes
yarn watch:css

# Type checking
yarn type-check

# Development server
yarn dev
```

## Using shadcn/ui Components

### In React Components
```tsx
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

export const MyComponent = () => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Title</CardTitle>
      </CardHeader>
      <CardContent>
        <Input placeholder="Enter text..." />
        <Button>Click me</Button>
      </CardContent>
    </Card>
  )
}
```

### In Rails Views
```erb
<div class="flex min-h-screen items-center justify-center bg-gray-50">
  <div class="w-full max-w-md space-y-8">
    <h2 class="text-center text-3xl font-bold">Title</h2>
    <!-- Your content -->
  </div>
</div>
```

## Next Steps

1. **Add more shadcn/ui components** as needed:
   ```bash
   # Example: Add more components from shadcn/ui
   # You can copy components from https://ui.shadcn.com/docs/components
   ```

2. **Create more React components** for complex UI interactions

3. **Update remaining views** to use Tailwind classes

4. **Add dark mode support** if needed (CSS variables are already configured)

5. **Consider adding more TypeScript** to your Rails views using React components

## Notes

- The login page now uses modern Tailwind styling instead of Bootstrap
- All user-facing strings are in Brazilian Portuguese as per project requirements
- The project maintains compatibility with Rails Hotwire/Turbo
- TypeScript is configured for better development experience
