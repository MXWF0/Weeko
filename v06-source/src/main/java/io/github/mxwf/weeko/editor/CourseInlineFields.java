package io.github.mxwf.weeko.editor;

import android.animation.Animator;
import android.animation.AnimatorListenerAdapter;
import android.app.Activity;
import android.app.Dialog;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.text.method.ArrowKeyMovementMethod;
import android.text.method.DigitsKeyListener;
import android.text.method.TextKeyListener;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.widget.HorizontalScrollView;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.lang.reflect.Method;
import java.util.ArrayList;

/** Binds inline controls to the existing editor beans and recommendation queries. */
public final class CourseInlineFields {
    private CourseInlineFields() {}

    private static int id(View root, String name) {
        return root.getResources().getIdentifier(name, "id", root.getContext().getPackageName());
    }

    private static Object call(Object target, String name, Class<?> parameter, Object value) {
        try {
            return parameter == null ? target.getClass().getMethod(name).invoke(target)
                    : target.getClass().getMethod(name, parameter).invoke(target, value);
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Original editor field binding failed: " + name, error);
        }
    }

    public static void base(View root, Object bean) {
        bind(root, "tv_credit", "ll_credit", bean, "Credit", -1);
        bind(root, "tv_note", "ll_note", bean, "Note", -1);
    }

    public static void detail(View root, Object bean, int position) {
        // The adapter's header occupies layout position 0; queries use data indices.
        bind(root, "et_teacher", "ll_teacher", bean, "Teacher", position - 1);
        bind(root, "et_room", "ll_room", bean, "Room", position - 1);
    }

    public static void unbind(View root) {
        for (String name : new String[]{"et_teacher", "et_room"}) {
            TextView field = root.findViewById(id(root, name));
            Binding binding = (Binding) field.getTag(field.getId());
            if (binding != null) {
                field.removeTextChangedListener(binding);
                binding.stopRecommendations();
                binding.recommendations.setVisibility(View.GONE);
                binding.choices.removeAllViews();
                field.setTag(field.getId(), null);
            }
        }
    }

    private static void bind(View root, String fieldName, String containerName, Object bean, String property, int position) {
        TextView field = root.findViewById(id(root, fieldName));
        ViewGroup container = root.findViewById(id(root, containerName));
        container.setBackground(null);
        boolean credit = property.equals("Credit");
        boolean note = property.equals("Note");
        Object value = call(bean, "get" + property, null, null);
        field.setKeyListener(credit ? DigitsKeyListener.getInstance(false, true)
                : TextKeyListener.getInstance(false, TextKeyListener.Capitalize.NONE));
        field.setRawInputType(credit ? 0x2000 : note ? 0x20001 : 1);
        field.setSingleLine(!note);
        if (note) field.setMaxLines(5);
        field.setMovementMethod(ArrowKeyMovementMethod.getInstance());
        field.setFocusableInTouchMode(true);
        field.setText(credit ? ((Float) value > 0 ? value.toString() : "") : (String) value, TextView.BufferType.EDITABLE);
        Binding binding = new Binding(field, bean, property, position, container);
        field.setTag(field.getId(), binding);
        field.addTextChangedListener(binding);
        if (credit || note) {
            container.setOnClickListener(view -> {
                field.requestFocus();
                ((android.view.inputmethod.InputMethodManager) field.getContext().getSystemService(Activity.INPUT_METHOD_SERVICE))
                        .showSoftInput(field, 0);
            });
        } else {
            // The existing adapter child listener still performs the original cached query.
            field.setOnFocusChangeListener((view, focused) -> {
                Binding current = (Binding) field.getTag(field.getId());
                if (current == null) return; // A recycled holder is between unbind and bind.
                if (focused) container.performClick();
                else current.hide();
            });
        }
        AddCourseAppearanceV120.inlineField(field);
    }

    public static boolean validate(Activity activity) {
        return validate(activity.findViewById(android.R.id.content));
    }

    private static boolean validate(View view) {
        if (view instanceof TextView && view.getId() > 0) {
            Object tag = view.getTag(view.getId());
            if (tag instanceof Binding && !((Binding) tag).write()) {
                view.requestFocus();
                return false;
            }
        }
        if (view instanceof ViewGroup) {
            ViewGroup group = (ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) if (!validate(group.getChildAt(i))) return false;
        }
        return true;
    }

    public static void recommendations(Activity activity, Object originalDialog, int position, int kind) {
        View focused = activity.getCurrentFocus();
        if (!(focused instanceof TextView) || focused.getId() <= 0) return;
        Object tag = focused.getTag(focused.getId());
        if (!(tag instanceof Binding)) return;
        Binding binding = (Binding) tag;
        if (binding.position != position || !binding.property.equals(kind == 0 ? "Teacher" : "Room")) return;
        try {
            Bundle args = (Bundle) originalDialog.getClass().getField("OooOO0o").get(originalDialog);
            binding.show(args.getStringArrayList("data"));
        } catch (ReflectiveOperationException error) {
            throw new IllegalStateException("Original course recommendations unavailable", error);
        }
    }

    /** Second back uses the existing negative action, including its actual NavHost destination. */
    public static void backPrompt(Dialog dialog) {
        dialog.setCanceledOnTouchOutside(false);
        dialog.setOnCancelListener(ignored -> {
            try {
                View leave = (View) dialog.getClass().getMethod("OooO0oo", int.class).invoke(dialog, -2);
                leave.performClick();
            } catch (ReflectiveOperationException error) {
                throw new IllegalStateException("Original discard action unavailable", error);
            }
        });
    }

    private static final class Binding implements TextWatcher {
        final TextView field;
        final Object bean;
        final String property;
        final int position;
        final Method setter;
        final HorizontalScrollView recommendations;
        final LinearLayout choices;
        View viewport;
        ViewTreeObserver.OnGlobalLayoutListener keyboardLayout;
        int viewportHeight;
        boolean expanded;

        Binding(TextView field, Object bean, String property, int position, ViewGroup container) {
            this.field = field;
            this.bean = bean;
            this.property = property;
            this.position = position;
            try {
                setter = bean.getClass().getMethod("set" + property, property.equals("Credit") ? float.class : String.class);
            } catch (NoSuchMethodException error) {
                throw new IllegalStateException("Original course setter missing", error);
            }
            if (position < 0) { recommendations = null; choices = null; return; }
            HorizontalScrollView existing = container.findViewWithTag("weeko_inline_recommendations");
            recommendations = existing == null ? new HorizontalScrollView(field.getContext()) : existing;
            if (existing == null) {
                recommendations.setTag("weeko_inline_recommendations");
                recommendations.setHorizontalScrollBarEnabled(false);
                choices = new LinearLayout(field.getContext());
                recommendations.addView(choices);
                container.addView(recommendations, new LinearLayout.LayoutParams(-1, -2));
            } else choices = (LinearLayout) recommendations.getChildAt(0);
            recommendations.setVisibility(View.GONE);
        }

        boolean write() {
            String text = field.getText().toString();
            Object value = text;
            if (property.equals("Credit")) {
                try { value = text.isEmpty() ? 0f : Float.parseFloat(text); }
                catch (NumberFormatException error) { field.setError("学分格式不正确"); return false; }
                if ((Float) value < 0) { field.setError("学分需大于或等于 0"); return false; }
            } else if (property.equals("Note") && text.length() > 300) {
                field.setError("备注不要超过 300 字"); return false;
            }
            field.setError(null);
            try { setter.invoke(bean, value); }
            catch (ReflectiveOperationException error) { throw new IllegalStateException("Original course field update failed", error); }
            return true;
        }

        void show(ArrayList<String> values) {
            if (values.isEmpty()) return;
            if (expanded) return;
            expanded = true;
            recommendations.animate().setListener(null).cancel();
            choices.removeAllViews();
            for (String value : values) {
                TextView chip = new TextView(field.getContext());
                chip.setText(value);
                AddCourseAppearanceV120.recommendation(chip);
                chip.setOnClickListener(view -> {
                    field.setText(value, TextView.BufferType.EDITABLE);
                    android.text.Selection.setSelection(field.getEditableText(), value.length());
                    chip.animate().scaleX(0.96f).scaleY(0.96f).setDuration(80).withEndAction(() ->
                            chip.animate().scaleX(1).scaleY(1).setDuration(120).start()).start();
                });
                choices.addView(chip);
            }
            if (recommendations.getVisibility() == View.GONE) recommendations.setAlpha(0);
            recommendations.setVisibility(View.VISIBLE);
            recommendations.animate().alpha(1).setDuration(160).start();
            // React to the actual IME resize, not a timer guessing when the keyboard opens.
            viewport = field.getRootView().findViewById(id(field, "anko_layout"));
            viewportHeight = viewport.getHeight();
            keyboardLayout = () -> {
                int height = viewport.getHeight();
                if (height != viewportHeight) {
                    viewportHeight = height;
                    revealRecommendations();
                }
            };
            viewport.getViewTreeObserver().addOnGlobalLayoutListener(keyboardLayout);
            revealRecommendations();
        }

        void revealRecommendations() {
            recommendations.post(() -> recommendations.requestRectangleOnScreen(
                    new android.graphics.Rect(0, 0, recommendations.getWidth(), recommendations.getHeight()), false));
        }

        void stopRecommendations() {
            expanded = false;
            recommendations.animate().setListener(null).cancel();
            if (keyboardLayout != null) {
                viewport.getViewTreeObserver().removeOnGlobalLayoutListener(keyboardLayout);
                keyboardLayout = null;
            }
        }

        void hide() {
            stopRecommendations();
            recommendations.animate().alpha(0).setDuration(140).setListener(new AnimatorListenerAdapter() {
                @Override public void onAnimationEnd(Animator animation) { recommendations.setVisibility(View.GONE); }
            }).start();
        }
        public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
        public void onTextChanged(CharSequence s, int start, int before, int count) {}
        public void afterTextChanged(Editable text) { write(); }
    }
}
