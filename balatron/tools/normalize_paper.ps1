# Windows PowerShell: transfer the approved neutral paper palette while retaining
# original texture, alpha, outlines and every pixel inside guarded artwork.
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
public static class PortraitPaper {
  static double PaperWeight(float x,float y,PointF[] p) {
    bool inside=false;double distance=10000;
    for(int i=0,j=p.Length-1;i<p.Length;j=i++) {
      PointF a=p[i], b=p[j];
      if((a.Y>y)!=(b.Y>y) && x<(b.X-a.X)*(y-a.Y)/(b.Y-a.Y)+a.X) inside=!inside;
      float dx=b.X-a.X,dy=b.Y-a.Y;
      if(dx==0 && dy==0) continue;
      float t=Math.Max(0,Math.Min(1,((x-a.X)*dx+(y-a.Y)*dy)/(dx*dx+dy*dy)));
      distance=Math.Min(distance,Math.Sqrt(Math.Pow(x-a.X-t*dx,2)+Math.Pow(y-a.Y-t*dy,2)));
    }
    return inside ? 0 : Math.Max(0,Math.Min(1,(distance-2)/4));
  }
  public static int Normalize(string source,string path,PointF[][] guards,Color reference) {
    using(var original=new Bitmap(source)) using(var output=new Bitmap(original)) {
      float scale=original.Height/95f;
      int changed=0;
      for(int y=0;y<original.Height;y++) for(int x=0;x<original.Width;x++) {
        int cell=(int)(x/(71*scale));
        double weight=PaperWeight(x/scale-cell*71,y/scale,guards[Math.Min(cell,guards.Length-1)]);
        if(weight==0) continue;
        Color c=original.GetPixel(x,y);
        if(c.A==0 || c.R<175 || c.G<145 || c.B<105 || c.R<c.G || c.G<c.B || c.R-c.G>42) continue;
        int green=(int)Math.Round(c.R*(reference.G/(double)reference.R)-(c.R-c.G)*0.12);
        int blue=(int)Math.Round(c.R*(reference.B/(double)reference.R)-(c.R-c.B)*0.12);
        green=c.G+(int)Math.Round(weight*Math.Max(0,Math.Min(255,green)-c.G));
        blue=c.B+(int)Math.Round(weight*Math.Max(0,Math.Min(255,blue)-c.B));
        output.SetPixel(x,y,Color.FromArgb(c.A,c.R,green,blue));
        if(green!=c.G || blue!=c.B) changed++;
      }
      output.Save(path,ImageFormat.Png);
      return changed;
    }
  }
}
'@
function New-Guard([int[]]$coords) {
    $points=for ($i=0;$i -lt $coords.Length;$i+=2) { [System.Drawing.PointF]::new($coords[$i],$coords[$i+1]) }
    return ,([System.Drawing.PointF[]]$points)
}
$projectRoot=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$paperRoot=Join-Path $projectRoot 'MODS\UPG JOKERS\PAPER'
$referenceImage=[System.Drawing.Bitmap]::new((Join-Path $paperRoot 'paper-reference.png'))
$reference=$referenceImage.GetPixel([int]($referenceImage.Width*0.13),[int]($referenceImage.Height*0.045))
$referenceImage.Dispose()
$bottomless=[System.Drawing.PointF[][]]@(
    (New-Guard @(20,10,43,10,57,16,62,34,59,50,60,70,65,78,57,88,26,93,8,83,4,61,11,42,10,31,12,18)),
    (New-Guard @(19,9,47,8,62,22,65,34,59,46,62,71,66,84,51,91,19,91,5,83,5,61,11,45,9,29,13,14)),
    (New-Guard @(22,4,43,4,62,13,68,28,63,49,65,74,66,87,39,95,9,90,3,80,4,47,9,32,10,20))
)
$riskGuards=New-Object 'System.Drawing.PointF[][]' 1
$riskGuards[0]=New-Guard @(22,10,45,11,59,23,65,46,65,70,67,87,44,93,16,91,3,82,4,66,7,50,12,31,10,24)
$changes=@()
foreach ($scale in 1,2) {
    foreach ($name in 'bottomless','greed','glass_cannon') {
        $mod=if ($name -eq 'bottomless') {'UPG JOKERS'} else {'RISK JOKERS'}
        $path=Join-Path $projectRoot "MODS\$mod\assets\${scale}x\$name.png"
        $backup=Join-Path $paperRoot "$name-${scale}x-original.png"
        $guards=$riskGuards
        if ($name -eq 'bottomless') { $guards=$bottomless }
        $count=[PortraitPaper]::Normalize($backup,$path,$guards,$reference)
        $changes+=@{asset="MODS/$mod/assets/${scale}x/$name.png";source_sha256=(Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash;output_sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash;paper_pixels=$count;artwork='Original pixels preserved within guarded silhouettes';reference_rgb=@($reference.R,$reference.G,$reference.B)}
    }
}
$changes | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $paperRoot 'normalization.json') -Encoding utf8
$changes | ForEach-Object { Write-Output ($_.asset+': '+$_.paper_pixels+' paper pixels') }
