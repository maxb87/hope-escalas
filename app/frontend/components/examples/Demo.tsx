import { Button } from "@/components/ui/button";

export function Demo() {
  return (
    <div className="flex items-center gap-4">
      <Button>Default</Button>
      <Button variant="secondary">Secondary</Button>
      <Button variant="outline">Outline</Button>
      <Button variant="destructive">Destructive</Button>
    </div>
  );
}


