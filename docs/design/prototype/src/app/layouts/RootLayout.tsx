import { Outlet, Link, useLocation } from 'react-router';
import { FileText, Search, FileSpreadsheet } from 'lucide-react';
import { Input } from '../components/ui/input';
import { Button } from '../components/ui/button';

export function RootLayout() {
  const location = useLocation();
  
  return (
    <div className="min-h-screen flex flex-col">
      {/* Header */}
      <header className="border-b bg-white sticky top-0 z-10">
        <div className="px-6 py-4">
          <div className="flex items-center justify-between">
            <Link to="/" className="flex items-center gap-2">
              <FileText className="h-6 w-6 text-primary" />
              <div>
                <h1 className="text-lg font-medium">WeighTags.com</h1>
                <p className="text-xs text-muted-foreground">Commodity Weigh Tag Reconciliation</p>
              </div>
            </Link>
            
            <div className="flex items-center gap-4">
              <div className="relative w-80">
                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input 
                  placeholder="Search by BOL, Load ID, Truck..." 
                  className="pl-9 bg-input-background"
                />
              </div>
              
              <Button variant="outline" size="sm">
                <FileSpreadsheet className="h-4 w-4 mr-2" />
                Export
              </Button>
              
              <div className="text-right text-sm">
                <div className="font-medium">Heartland Grain Co.</div>
                <div className="text-xs text-muted-foreground">jessica.miller@heartlandgrain.com</div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1">
        <Outlet />
      </main>

      {/* Footer */}
      <footer className="border-t bg-white py-4 px-6">
        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <div>© 2026 WeighTags.com • System of Record for Commodity Weight Reconciliation</div>
          <div className="flex items-center gap-4">
            <span>CST (UTC-5)</span>
            <span>•</span>
            <span>Last sync: 2026-05-27 17:45:00</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
