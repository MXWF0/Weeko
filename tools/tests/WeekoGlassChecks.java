package io.github.mxwf.weeko.popup;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import io.github.mxwf.weeko.about.G2ShapeDrawable;
import java.util.Arrays;
import java.util.Random;

/** Android pixel/performance checks; no user data and no saved screenshots. */
public final class WeekoGlassChecks {
    private static void original(Bitmap bitmap, int radius) {
        int width = bitmap.getWidth(), height = bitmap.getHeight();
        int[] input = new int[width * height], horizontal = new int[input.length], output = new int[input.length];
        bitmap.getPixels(input, 0, width, 0, 0, width, height);
        for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) {
            int r=0,g=0,b=0,n=0;
            for(int offset=-radius;offset<=radius;offset++) {
                int c=input[y*width+Math.max(0,Math.min(width-1,x+offset))]; r+=(c>>16)&255;g+=(c>>8)&255;b+=c&255;n++;
            }
            horizontal[y*width+x]=0xff000000|(r/n<<16)|(g/n<<8)|b/n;
        }
        for (int y = 0; y < height; y++) for (int x = 0; x < width; x++) {
            int r=0,g=0,b=0,n=0;
            for(int offset=-radius;offset<=radius;offset++) {
                int c=horizontal[Math.max(0,Math.min(height-1,y+offset))*width+x]; r+=(c>>16)&255;g+=(c>>8)&255;b+=c&255;n++;
            }
            output[y*width+x]=0xff000000|(r/n<<16)|(g/n<<8)|b/n;
        }
        bitmap.setPixels(output,0,width,0,0,width,height);
    }

    private static Bitmap sample(int width, int height) {
        int[] pixels = new int[width * height];
        Random random = new Random(115);
        for (int i=0;i<pixels.length;i++) pixels[i]=0xff000000|random.nextInt(0x1000000);
        return Bitmap.createBitmap(pixels,width,height,Bitmap.Config.ARGB_8888).copy(Bitmap.Config.ARGB_8888,true);
    }

    public static void main(String[] args) {
        for(int width:new int[]{1,3,17,153}) for(int radius:new int[]{1,3,5}) {
            Bitmap old=sample(width,29), current=old.copy(Bitmap.Config.ARGB_8888,true);
            original(old,radius);GlassPopupBackground.blur(current,radius);
            if(!old.sameAs(current)) throw new AssertionError("Blur pixels differ: "+width+"/"+radius);
            old.recycle();current.recycle();
        }
        System.out.println("PASS: 12 blur edge/size/radius cases, pixels identical");
        Bitmap shape=Bitmap.createBitmap(200,120,Bitmap.Config.ARGB_8888);
        G2ShapeDrawable background=new G2ShapeDrawable(Color.WHITE,0,0,24);
        background.setBounds(0,0,200,120);background.draw(new Canvas(shape));
        if(Color.alpha(shape.getPixel(0,0))!=0 || Color.alpha(shape.getPixel(199,119))!=0
                || Color.alpha(shape.getPixel(100,60))!=255) throw new AssertionError("G2 corner mask incorrect");
        background.setAlpha(128);shape.eraseColor(0);background.draw(new Canvas(shape));
        if(Color.alpha(shape.getPixel(100,60))!=128) throw new AssertionError("Alpha not preserved");
        System.out.println("PASS: G2 corners, center and alpha");
        long[] before=new long[100],after=new long[100];
        for(int i=0;i<120;i++) {
            Bitmap old=sample(153,147),current=old.copy(Bitmap.Config.ARGB_8888,true);
            long time=System.nanoTime();original(old,5);long oldTime=System.nanoTime()-time;
            time=System.nanoTime();GlassPopupBackground.blur(current,5);long newTime=System.nanoTime()-time;
            if(i>=20) {before[i-20]=oldTime;after[i-20]=newTime;}
            old.recycle();current.recycle();
        }
        Arrays.sort(before);Arrays.sort(after);
        System.out.println("Blur 153x147 radius5 n=100 median us: old="+before[50]/1000+" new="+after[50]/1000
                +"; P95 us: old="+before[95]/1000+" new="+after[95]/1000);
        System.out.println("Popup bitmap bytes 612x588: old="+(612*588*4+153*147*4)+" new="+(153*147*4));
    }
}
