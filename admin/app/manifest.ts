import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "PRAMAAN",
    short_name: "PRAMAAN",
    description: "Proof, not promises.",
    start_url: "/",
    display: "standalone",
    background_color: "#f6f7f4",
    theme_color: "#071c2f",
    icons: [],
  };
}
