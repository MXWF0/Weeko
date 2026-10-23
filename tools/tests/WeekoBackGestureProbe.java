import android.os.SystemClock;
import android.view.InputDevice;
import android.view.InputEvent;
import android.view.MotionEvent;
import java.lang.reflect.Method;

/** ADB-shell test driver for one continuous gesture on the connected API 34+ device.
 * Not application code. Separate `input motionevent` processes do not retain a
 * common event downTime and cannot establish a cancelled predictive gesture. */
public final class WeekoBackGestureProbe {
    public static void main(String[] args) throws Exception {
        int width = Integer.parseInt(args[0]);
        float y = Float.parseFloat(args[1]);
        boolean cancel = args[2].equals("cancel");
        Class<?> managerType = Class.forName("android.hardware.input.InputManagerGlobal");
        Object manager = managerType.getMethod("getInstance").invoke(null);
        Method inject = managerType.getMethod("injectInputEvent", InputEvent.class, int.class);
        long down = SystemClock.uptimeMillis();
        float edge = width - 2f;
        for (int step = 0; step <= 40; step++) {
            float fraction = step / 40f;
            float distance = cancel ? 300f * (float) Math.sin(Math.PI * fraction) : width * 0.5f * fraction;
            int action = step == 0 ? MotionEvent.ACTION_DOWN : step == 40 ? MotionEvent.ACTION_UP : MotionEvent.ACTION_MOVE;
            MotionEvent event = MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, edge - distance, y, 0);
            event.setSource(InputDevice.SOURCE_TOUCHSCREEN);
            boolean injected = (Boolean) inject.invoke(manager, event, 2);
            event.recycle();
            if (!injected) throw new IllegalStateException("Gesture injection rejected at step " + step);
            SystemClock.sleep(25);
        }
        System.out.println("Injected continuous " + args[2] + " gesture; UI/trace checks are still required.");
    }
}
