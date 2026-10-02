import brut.androlib.mod.SmaliMod;
import com.android.tools.smali.dexlib2.Opcodes;
import com.android.tools.smali.dexlib2.writer.builder.DexBuilder;
import java.io.File;

public final class WeekoSmaliCheck {
    public static void main(String[] args) {
        DexBuilder builder = new DexBuilder(new Opcodes(35, -1));
        for (String path : args) {
            if (!SmaliMod.assembleSmaliFile(new File(path), builder, 35)) {
                throw new AssertionError("Smali assembly failed: " + path);
            }
        }
        System.out.println("PASS: callback smali assembly (not ART verification)");
    }
}
