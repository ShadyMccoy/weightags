import { createBrowserRouter } from "react-router";
import { RootLayout } from "./layouts/RootLayout";
import { LoadsListPage } from "./pages/LoadsListPage";
import { LoadDetailPage } from "./pages/LoadDetailPage";
import { NotFoundPage } from "./pages/NotFoundPage";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: RootLayout,
    children: [
      { index: true, Component: LoadsListPage },
      { path: "weigh-tags/:loadId", Component: LoadDetailPage },
      { path: "*", Component: NotFoundPage },
    ],
  },
]);
